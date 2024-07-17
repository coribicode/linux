######################################
# Informação da versão do Debian     #
######################################
DEBIAN_VERSION_CODENOME=$(cat /etc/*release* | grep CODENAME | cut -d '=' -f 2)
DEBIAN_VERSION_ID=$(cat /etc/*release* | grep VERSION_ID | cut -d '"' -f 2)

######################################
# Informação do IP atual             #
######################################
HOST_IP=$(hostname -I | cut -d ' ' -f1)

######################################
# Instalação dos Pacotes Essenciais  #
######################################
apt update && apt upgrade -y
systemctl daemon-reload
apt install -y sudo wget build-essential

############################################
# Informações do TomCat                    #
# https://dlcdn.apache.org/tomcat/         #
############################################

# Repositório Bullseye par o TomCat9 #
echo "deb http://deb.debian.org/debian/ bullseye main" >> /etc/apt/sources.list.d/tomcat.list

apt update

TOMCAT_VERSION=9
sudo apt install -y tomcat$TOMCAT_VERSION
sudo systemctl enable --now tomcat$TOMCAT_VERSION

############################################
# Informações da Guacamole Server e Client #
# https://dlcdn.apache.org/guacamole/      #
############################################
GUAC_VERSION=1.5.5

# Instalação de dependências         #
apt install -y libcairo2-dev libjpeg62-turbo-dev libpng-dev libtool-bin uuid-dev libossp-uuid-dev

# Instalação de Outras dependências  #
apt install -y libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev  libssl-dev libvorbis-dev libwebp-dev
apt install -y libguac-client-rdp0 libguac-client-ssh0 libguac-client-telnet0 libguac-client-vnc0
apt install -y libguac19
apt install -y libguac-dev


URI_DOWNLOAD_GUAC_SERVER=https://dlcdn.apache.org/guacamole/$GUAC_VERSION/source/guacamole-server-$GUAC_VERSION.tar.gz
wget -P /opt/ $URI_DOWNLOAD_GUAC_SERVER

tar -C /opt/ -xzf /opt/guacamole-server-$GUAC_VERSION.tar.gz
cd /opt/guacamole-server-$GUAC_VERSION

#export CFLAGS="-Wno-error"
#./configure --with-systemd-dir=/etc/systemd/system/ --disable-dependency-tracking

./configure --with-systemd-dir=/etc/systemd/system/ --disable-dependency-tracking --disable-guacenc

make
make install

echo 'export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin' >> ~/.bashrc
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin

source /etc/profile

sudo ldconfig

sudo systemctl daemon-reload
sudo systemctl enable --now guacd

######################################
# Informações do Banco de Dados      #
######################################
apt install -y mariadb-server

GUAC_DB=guac_db
GUAC_DB_USER=guac_user
GUAC_DB_USER_PWD=guac_password

cat >> /opt/config.sql << EOL
CREATE DATABASE $GUAC_DB;
CREATE USER '$GUAC_DB_USER'@'localhost' IDENTIFIED BY '$GUAC_DB_USER_PWD';
GRANT SELECT,INSERT,UPDATE,DELETE ON $GUAC_DB.* TO $GUAC_DB_USER@localhost;
FLUSH PRIVILEGES;
EOL

mysql -u root < /opt/config.sql

# mysql -u root -e "SELECT user FROM mysql.user;"
# mysql -u root -e "show databases;"

####################################
# Informações de Extensões do Guac #
####################################

mkdir -p /etc/guacamole

mkdir -p /etc/guacamole/extensions

mkdir -p /etc/guacamole/lib

echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat$TOMCAT_VERSION

ln -s /etc/guacamole /usr/share/tomcat$TOMCAT_VERSION/.guacamole

#######################################
# Informações do Web Application WAR  #
# https://dlcdn.apache.org/guacamole/ #
#######################################
URI_DOWNLOAD_WAR=https://dlcdn.apache.org/guacamole/"$GUAC_VERSION"/binary/guacamole-"$GUAC_VERSION".war
wget -P /opt/ $URI_DOWNLOAD_WAR
cp /opt/guacamole-*.war /etc/guacamole/guacamole.war
sudo ln -s /etc/guacamole/guacamole.war /var/lib/tomcat$TOMCAT_VERSION/webapps

################################################
# Informação do Java Database Authentication   #
# https://dlcdn.apache.org/guacamole/          #
################################################
URI_DOWNLOAD_AUTH_JDBC=https://dlcdn.apache.org/guacamole/$GUAC_VERSION/binary/guacamole-auth-jdbc-$GUAC_VERSION.tar.gz
wget -P /opt/ $URI_DOWNLOAD_AUTH_JDBC
tar -C /opt/ -xf /opt/guacamole-auth-jdbc-*.tar.gz
cat /opt/guacamole-auth-jdbc-*/mysql/schema/*.sql | mysql -u root $GUAC_DB
cp /opt/guacamole-auth-jdbc-*/mysql/guacamole-auth-jdbc-mysql-*.jar /etc/guacamole/extensions/guacamole-auth-jdbc-mysql.jar

################################################
# Informação do Conector Mysql Java            #
# https://downloads.mysql.com/archives/c-j/    #
# https://dev.mysql.com/downloads/connector/j/ #
################################################
MYSQL_CONNECTOR_JAVA_VERSION=9.0.0
URI_DOWNLOAD_MYSQL_CONNECTOR_JAVA=https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-j_"$MYSQL_CONNECTOR_JAVA_VERSION"-1debian"$DEBIAN_VERSION_ID"_all.deb
wget -P /opt/ $URI_DOWNLOAD_MYSQL_CONNECTOR_JAVA

dpkg -i /opt/mysql-connector-j_*_all.deb

cp /usr/share/java/mysql-connector-java-*.jar /etc/guacamole/lib/mysql-connector.jar

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

#######################################
# Reiniciando Serviços                #
#######################################
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
sudo systemctl daemon-reload
sudo systemctl restart guacd
sudo systemctl restart tomcat$TOMCAT_VERSION

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

echo
echo "Status do Arquivo do NGINX com Proxy Reverso da porta 8080"
echo "---------------------------------------------------------"
sudo nginx -t
echo "---------------------------------------------------------"
echo
echo "Status do Guacd"
echo "---------------------------------------------------------"
sudo service guacd status | grep -E "Loaded|Active"
echo "---------------------------------------------------------"
echo
echo "Status do TomCat$TOMCAT_VERSION"
echo "---------------------------------------------------------"
sudo service tomcat$TOMCAT_VERSION status | grep -E "Loaded|Active"
echo "---------------------------------------------------------"
echo 
echo "Instalação concluída!"
echo
echo "---------------------------------------------------------"
echo "Acesse via broswer http://$(hostname -I | cut -d ' ' -f1)"
echo
echo "Usuario: guacadmin"
echo "Senha: guacadmin"
echo "---------------------------------------------------------"
echo

######################################
# Autenticação duplo Fator TOTP      #
######################################

# wget -P /opt/ https://dlcdn.apache.org/guacamole/"$GUAC_VERSION"/binary/guacamole-auth-totp-"$GUAC_VERSION".tar.gz
# tar -zxf /opt/guacamole-auth-totp-"$GUAC_VERSION".tar.gz -C /opt/
# cp /opt/guacamole-auth-totp-"$GUAC_VERSION"/guacamole-auth-totp-"$GUAC_VERSION".jar /etc/guacamole/extensions/

