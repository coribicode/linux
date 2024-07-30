#!/bin/bash
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


echo
echo "Instalando Guacamole Server $GUAC_VERSION ..."
echo

FILE=/etc/apt/sources.list.d/guac.list
if [ -e $FILE ];
  then
  apt update 2>&1 | grep "E:"
else
  echo "deb http://deb.debian.org/debian/ bullseye main" >> $FILE
  apt update 2>&1 | grep "E:"
fi

if grep PACKAGE_NAME $INSTALLER 2>&1
  then
    sed -i "s|PACKAGE_NAME|$package_list|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi

cat > DIR_GUAC << EOF
/etc/guacamole
/etc/guacamole/system
/etc/guacamole/download
/etc/guacamole/config
/etc/guacamole/extensions
/etc/guacamole/lib
EOF

for directoy in $(cat DIR_GUAC)
do
  if [ -d $directoy ];
    then
      echo "[ $directoy ]: OK!"
    else
      echo "[ $directoy ]: Criando ..."
      mkdir -p $directoy
      sleep 2
      echo "[ $directoy ]: OK!"
  fi
done

FILE=/etc/guacamole/config/config.sql
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Criando ..."
cat > $FILE << EOF
CREATE DATABASE $GUAC_DB;
CREATE USER '$GUAC_DB_USER'@'localhost' IDENTIFIED BY '$GUAC_DB_USER_PWD';
GRANT SELECT,INSERT,UPDATE,DELETE ON $GUAC_DB.* TO $GUAC_DB_USER@localhost;
FLUSH PRIVILEGES;
EOF
mysql -u root < $FILE
    sleep 2
    echo "[ $FILE ]: OK!"
fi

FILE=/etc/guacamole/guacamole.properties
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Criando ..."
cat > $FILE << EOF
mysql-hostname: localhost
mysql-port: 3306
mysql-database: $GUAC_DB
mysql-username: $GUAC_DB_USER
mysql-password: $GUAC_DB_USER_PWD
EOF
    sleep 2
    echo "[ $FILE ]: OK!"
fi

FILE=/etc/guacamole/guacd.conf
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Criando ..."
cat > /etc/guacamole/guacd.conf << EOF
[server]
bind_host = 0.0.0.0
bind_port = 4822
EOF
    sleep 2
    echo "[ $FILE ]: OK!"
fi

FILE=/etc/guacamole/download/guacamole-server-$GUAC_VERSION.tar.gz
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Baixando ..."
wget $URI_DOWNLOAD_GUAC_SERVER -P /etc/guacamole/download/ 2>&1 | grep "E:"
    echo "[ $FILE ]: Instalando ..."
tar -xzf /etc/guacamole/download/guacamole-server-$GUAC_VERSION.tar.gz -C /etc/guacamole/system/ 2>&1 | grep "E:"
mv /etc/guacamole/system/guacamole-server-$GUAC_VERSION /etc/guacamole/system/guacamole-server
cd /etc/guacamole/system/guacamole-server
./configure --with-systemd-dir=/etc/systemd/system/ 2>&1 | grep "E:"
make 2>&1 | grep "E:"
make install 2>&1 | grep "E:"
sudo systemctl enable --now guacd
    echo "[ $FILE ]: OK!"
fi

FILE=/etc/guacamole/download/guacamole-auth-jdbc-*.tar.gz
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Baixando ..."
wget $URI_DOWNLOAD_AUTH_JDBC -P /etc/guacamole/download/ 2>&1 | grep "E:"
    echo "[ $FILE ]: Instalando ..."
tar -xf /etc/guacamole/download/guacamole-auth-jdbc-*.tar.gz -C /etc/guacamole/download/ 2>&1 | grep "E:"
cat /etc/guacamole/download/guacamole-auth-jdbc-*/mysql/schema/*.sql | mysql -u root $GUAC_DB
cp /etc/guacamole/download/guacamole-auth-jdbc-*/mysql/guacamole-auth-jdbc-mysql-*.jar /etc/guacamole/extensions/guacamole-auth-jdbc-mysql.jar
    echo "[ $FILE ]: OK!"
fi

FILE=/etc/guacamole/download/mysql-connector-j_*_all.deb
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Baixando ..."
wget $URI_DOWNLOAD_MYSQL_CONNECTOR_JAVA -P /etc/guacamole/download/ 2>&1 | grep "E:"
    echo "[ $FILE ]: Instalando ..."
sudo dpkg -i /etc/guacamole/download/mysql-connector-j_*_all.deb 2>&1 | grep "E:"
    echo "[ $FILE ]: Configurando ..."
cp /usr/share/java/mysql-connector-java-*.jar /etc/guacamole/lib/mysql-connector.jar
  echo "[ $FILE ]: OK!"
fi

FILE=/etc/guacamole/download/guacamole-*.war
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Baixando ..."
wget $URI_DOWNLOAD_WAR -P /etc/guacamole/download/ 2>&1 | grep "E:"
    echo "[ $FILE ]: Configurando ..."
cp /etc/guacamole/download/guacamole-*.war /etc/guacamole/guacamole.war
    sleep 2
  echo "[ $FILE ]: OK!"    
fi

GUAC_VARIABLE="GUACAMOLE_HOME=/etc/guacamole"
TOMCAT_FILE="/etc/default/tomcat$TOMCAT_VERSION"

if grep $GUAC_VARIABLE $TOMCAT_FILE > /dev/null
  then
	  echo "[ $GUAC_VARIABLE ]: OK"
  else
  echo "[ $GUAC_VARIABLE ]: Configurando ..."
echo 'GUACAMOLE_HOME=/etc/guacamole' > /etc/default/tomcat$TOMCAT_VERSION
  sleep 2
  echo "[ $GUAC_VARIABLE ]: OK"
fi

FILE=/var/lib/tomcat$TOMCAT_VERSION/webapps/guacamole.war
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Configurando ..."
ln -s /etc/guacamole/guacamole.war /var/lib/tomcat$TOMCAT_VERSION/webapps
  sleep 2
  echo "[ $FILE ]: OK!"
fi

DIR=/usr/share/tomcat$TOMCAT_VERSION/.guacamole
if [ -d $DIR ];
  then
    echo "[ $DIR ]: OK!"
  else
  echo "[ $DIR ]: Configurando ...."
ln -s /etc/guacamole $DIR
  sleep 2
  echo "[ $DIR ]: OK!"
fi

sudo systemctl enable --now tomcat$TOMCAT_VERSION
sudo systemctl restart guacd
sudo systemctl restart tomcat$TOMCAT_VERSION

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
