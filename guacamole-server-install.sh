apt install -y curl 2>/dev/null | grep "E:"
curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/debian_stable_repository.sh 2>/dev/null | grep "E:"
sh debian_stable_repository.sh

curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh 2>/dev/null | grep "E:"
INSTALLER="install.sh"

GUAC_VERSION=1.5.5
TOMCAT_VERSION=9
MYSQL_CONNECTOR_JAVA_VERSION=9.0.0

GUAC_DB=guac_db_name
GUAC_DB_USER=guac_db_user
GUAC_DB_USER_PWD=guac_db_password

DEBIAN_VERSION_CODENOME=$(cat /etc/*release* | grep CODENAME | cut -d '=' -f 2)
DEBIAN_VERSION_ID=$(cat /etc/*release* | grep VERSION_ID | cut -d '"' -f 2)
HOST_IP=$(hostname -I | cut -d ' ' -f1)

PACKAGES_ESSENTIALS="sudo wget make"
PACKAGES_DEPENDECES="tomcat$TOMCAT_VERSION mariadb-server"
PACKAGES_LIBS="uuid-dev freerdp2-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev  libssl-dev libvorbis-dev libwebp-dev libcairo2-dev libjpeg62-turbo-dev libpango1.0-dev libssh2-1-dev"
package_list="$PACKAGES_ESSENTIALS $PACKAGES_DEPENDECES $PACKAGES_LIBS"

URI_DOWNLOAD_GUAC_SERVER=https://dlcdn.apache.org/guacamole/$GUAC_VERSION/source/guacamole-server-$GUAC_VERSION.tar.gz
URI_DOWNLOAD_WAR=https://dlcdn.apache.org/guacamole/$GUAC_VERSION/binary/guacamole-$GUAC_VERSION.war
URI_DOWNLOAD_AUTH_JDBC=https://dlcdn.apache.org/guacamole/$GUAC_VERSION/binary/guacamole-auth-jdbc-$GUAC_VERSION.tar.gz
URI_DOWNLOAD_MYSQL_CONNECTOR_JAVA=https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-j_"$MYSQL_CONNECTOR_JAVA_VERSION"-1debian"$DEBIAN_VERSION_ID"_all.deb

echo 'export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin' >> ~/.bashrc
systemctl daemon-reload
source /etc/profile
ldconfig

echo
echo "Instalando Guacamole Server $GUAC_VERSION..."
echo

cat >> INSTALL_GUAC_SERVER << EOF

if [ -e /etc/apt/sources.list.d/guac.list ];
  then
  apt update 2>&1 | grep "E:"
else
  echo "deb http://deb.debian.org/debian/ bullseye main" >> /etc/apt/sources.list.d/guac.list
  apt update 2>&1 | grep "E:"
fi

sed -i "s|PACKAGE_NAME|$package_list|g" $INSTALLER
sh $INSTALLER

echo
mkdir -p /etc/guacamole
mkdir -p /etc/guacamole/system
mkdir -p /etc/guacamole/download
mkdir -p /etc/guacamole/config
mkdir -p /etc/guacamole/extensions
mkdir -p /etc/guacamole/lib

wget $URI_DOWNLOAD_GUAC_SERVER -P /etc/guacamole/download/
tar -xzf /etc/guacamole/download/guacamole-server-$GUAC_VERSION.tar.gz -C /etc/guacamole/system/
mv /etc/guacamole/system/guacamole-server-$GUAC_VERSION /etc/guacamole/system/guacamole-server
cd /etc/guacamole/system/guacamole-server
./configure --with-systemd-dir=/etc/systemd/system/
make
make install
sudo systemctl enable --now guacd

cat >> /etc/guacamole/config/config.sql << EOL
CREATE DATABASE $GUAC_DB;
CREATE USER '$GUAC_DB_USER'@'localhost' IDENTIFIED BY '$GUAC_DB_USER_PWD';
GRANT SELECT,INSERT,UPDATE,DELETE ON $GUAC_DB.* TO $GUAC_DB_USER@localhost;
FLUSH PRIVILEGES;
EOL
mysql -u root < /etc/guacamole/config/config.sql

cat >> /etc/guacamole/guacamole.properties << EOL
mysql-hostname: localhost
mysql-port: 3306
mysql-database: $GUAC_DB
mysql-username: $GUAC_DB_USER
mysql-password: $GUAC_DB_USER_PWD
EOL

cat >> /etc/guacamole/guacd.conf << EOL
[server]
bind_host = 0.0.0.0
bind_port = 4822
EOL

wget $URI_DOWNLOAD_AUTH_JDBC -P /etc/guacamole/download/
tar -xf /etc/guacamole/download/guacamole-auth-jdbc-*.tar.gz -C /etc/guacamole/download/
cat /etc/guacamole/download/guacamole-auth-jdbc-*/mysql/schema/*.sql | mysql -u root $GUAC_DB
cp /etc/guacamole/download/guacamole-auth-jdbc-*/mysql/guacamole-auth-jdbc-mysql-*.jar /etc/guacamole/extensions/guacamole-auth-jdbc-mysql.jar

wget $URI_DOWNLOAD_MYSQL_CONNECTOR_JAVA -P /etc/guacamole/download/
systemctl daemon-reload
source /etc/profile
ldconfig
dpkg -i /etc/guacamole/download/mysql-connector-j_*_all.deb
cp /usr/share/java/mysql-connector-java-*.jar /etc/guacamole/lib/mysql-connector.jar

wget $URI_DOWNLOAD_WAR -P /etc/guacamole/download/
cp /etc/guacamole/download/guacamole-*.war /etc/guacamole/guacamole.war

echo 'GUACAMOLE_HOME=/etc/guacamole' >> /etc/default/tomcat$TOMCAT_VERSION
ln -s /etc/guacamole/guacamole.war /var/lib/tomcat$TOMCAT_VERSION/webapps
ln -s /etc/guacamole /usr/share/tomcat$TOMCAT_VERSION/.guacamole

sudo systemctl enable --now tomcat$TOMCAT_VERSION
sudo systemctl restart guacd
sudo systemctl restart tomcat$TOMCAT_VERSION

EOF

sh INSTALL_GUAC_SERVER

echo "Instalado"

######################################
# Instalação NGINX com Proxy Reverso #
######################################

sudo apt install nginx -y

cat <<'EOF'>> /etc/nginx/sites-available/guacamole
server {
    listen 80; # 443 ssl http2
    server_name HOST_IP;
    
    root /var/www/html;
    index index.html;
    access_log /var/log/nginx/guacamole-access.log;
    error_log /var/log/nginx/guacamole-error.log;

    #ssl_certificate /etc/letsencrypt/live/example.io/fullchain.pem;
    #ssl_certificate_key /etc/letsencrypt/live/example.io/privkey.pem;
    #rewrite ^ https://$server_name$request_uri? permanent;

    #location / {
    #   try_files $uri $uri/ =404;
    #}

    location / {
        proxy_pass http://127.0.0.1:8080/guacamole/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;
        access_log off;
    }
}
EOF

sudo sed -i "s/HOST_IP/$HOST_IP/g" /etc/nginx/sites-available/guacamole

sudo ln -s /etc/nginx/sites-available/guacamole /etc/nginx/sites-enabled/

sudo systemctl restart nginx

##########################################
# CORREÇÃO DE FALHA DE LOGIN RDP WINDOWS #
##########################################
cp /etc/systemd/system/guacd.service /etc/systemd/system/guacd.service.bkp
sudo sed -i "s/User=daemon/User=root/g" /etc/systemd/system/guacd.service

sudo systemctl daemon-reload
sudo systemctl restart guacd
sudo systemctl restart tomcat"$TOMCAT_VERSION"
