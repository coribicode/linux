#!/bin/bash
apt install -y curl 2>/dev/null | grep "E:"
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
PACKAGES_DEPENDECES="tomcat$TOMCAT_VERSION mariadb-server nginx"
PACKAGES_LIBS="uuid-dev freerdp2-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev  libssl-dev libvorbis-dev libwebp-dev libcairo2-dev libjpeg62-turbo-dev libpango1.0-dev libssh2-1-dev"
package_list="$PACKAGES_ESSENTIALS $PACKAGES_DEPENDECES $PACKAGES_LIBS"

URI_DOWNLOAD_GUAC_SERVER=https://dlcdn.apache.org/guacamole/$GUAC_VERSION/source/guacamole-server-$GUAC_VERSION.tar.gz
URI_DOWNLOAD_WAR=https://dlcdn.apache.org/guacamole/$GUAC_VERSION/binary/guacamole-$GUAC_VERSION.war
URI_DOWNLOAD_AUTH_JDBC=https://dlcdn.apache.org/guacamole/$GUAC_VERSION/binary/guacamole-auth-jdbc-$GUAC_VERSION.tar.gz
URI_DOWNLOAD_MYSQL_CONNECTOR_JAVA=https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-j_"$MYSQL_CONNECTOR_JAVA_VERSION"-1debian"$DEBIAN_VERSION_ID"_all.deb


echo
echo "Instalando Guacamole Server $GUAC_VERSION ..."
echo

echo
echo "[ guac.list ]"
FILE=/etc/apt/sources.list.d/guac.list
if [ -e $FILE ];
  then
  echo "[ ]: Atualizando repositorio Guacamole ..."
  apt update 2>&1 | grep "E:"
  sleep 2
  echo "[ $FILE ]: OK!"
else
  echo "[ $FILE ]: Adicioando repositorio Guacamole ..."
  echo "deb http://deb.debian.org/debian/ bullseye main" >> $FILE
  sleep 2
  echo "[ $FILE ]: OK!"
  echo "[ $FILE ]: Atualizando repositorio Guacamole ..."
  apt update 2>&1 | grep "E:"
  sleep 2
  echo "[ $FILE ]: OK!"
fi
echo "[ guac.list ]: OK!"
sleep 2

echo
echo "[ Instalação de Pacotes ]"
if grep PACKAGE_NAME $INSTALLER > /dev/null
  then
    sed -i "s|PACKAGE_NAME|$package_list|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ Instalação de Pacotes ]: OK!"
sleep 2

echo
echo "[ Diretório Guacamole Server ]"
cat > DIR_GUAC << EOF
/etc/guacamole
/etc/guacamole/system
/etc/guacamole/system/ssl
/etc/guacamole/system/download
/etc/guacamole/system/config
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
echo "[ Diretório Guacamole Server ]: OK!"
sleep 2

DIR_GUAC=/etc/guacamole
DIR_GUAC_SYSTEM=/etc/guacamole/system
DIR_GUAC_SSL=/etc/guacamole/system/ssl
DIR_GUAC_DOWNLOAD=/etc/guacamole/system/download
DIR_GUAC_CONFIG=/etc/guacamole/system/config
DIR_GUAC_EXTENSION=/etc/guacamole/extensions
DIR_GUAC_LIB=/etc/guacamole/lib

echo
echo "[ config.sql ]"
FILE=$DIR_GUAC_CONFIG/config.sql
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
echo "[ config.sql ]: OK"
sleep 2

echo
echo "[ guacamole.properties ]"
FILE=$DIR_GUAC/guacamole.properties
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
echo "[ guacamole.properties ]: OK!"
sleep 2

echo
echo "[ guacd.conf ]"
FILE=$DIR_GUAC/guacd.conf
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Criando ..."
cat > $FILE << EOF
[server]
bind_host = 0.0.0.0
bind_port = 4822
EOF
    sleep 2
    echo "[ $FILE ]: OK!"
fi
echo "[ guacd.conf ]: OK!"
sleep 2

echo
echo "[ guacamole-server-$GUAC_VERSION.tar.gz ]"
FILE=$DIR_GUAC_DOWNLOAD/guacamole-server-$GUAC_VERSION.tar.gz
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Baixando ..."
wget $URI_DOWNLOAD_GUAC_SERVER -P $DIR_GUAC_DOWNLOAD/ 2>&1 | grep "E:"
    echo "[ $FILE ]: Instalando ..."
tar -xzf $FILE -C $DIR_GUAC_SYSTEM/ 2>&1 | grep "E:"
mv $DIR_GUAC_SYSTEM/guacamole-server-$GUAC_VERSION $DIR_GUAC_SYSTEM/guacamole-server
cd $DIR_GUAC_SYSTEM/guacamole-server
./configure --with-systemd-dir=/etc/systemd/system/ 2>&1 | grep "E:"
make 2>&1 | grep "E:"
make install 2>&1 | grep "E:"
sudo systemctl enable --now guacd 2>&1 | grep "E:"
    echo "[ $FILE ]: OK!"
fi
echo "[ guacamole-server-$GUAC_VERSION.tar.gz ]: OK!"
sleep 2

echo
echo "[ guacamole-auth-jdbc-mysql-*.jar ]"
FILE=$DIR_GUAC_DOWNLOAD/guacamole-auth-jdbc-*.tar.gz
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Baixando ..."
wget $URI_DOWNLOAD_AUTH_JDBC -P $DIR_GUAC_DOWNLOAD/ 2>&1 | grep "E:"
    echo "[ $FILE ]: Instalando ..."
tar -xf $FILE -C $DIR_GUAC_DOWNLOAD/ 2>&1 | grep "E:"
cat $DIR_GUAC_DOWNLOAD/guacamole-auth-jdbc-*/mysql/schema/*.sql | mysql -u root $GUAC_DB
cp $DIR_GUAC_DOWNLOAD/guacamole-auth-jdbc-*/mysql/guacamole-auth-jdbc-mysql-*.jar $DIR_GUAC_EXTENSION/guacamole-auth-jdbc-mysql.jar
    echo "[ $FILE ]: OK!"
fi
echo "[ guacamole-auth-jdbc-mysql-*.jar ]: OK!"
sleep 2

echo
echo "[ mysql-connector-j_*_all.deb ]"
FILE=$DIR_GUAC_DOWNLOAD/mysql-connector-j_*_all.deb
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Baixando ..."
wget $URI_DOWNLOAD_MYSQL_CONNECTOR_JAVA -P $DIR_GUAC_DOWNLOAD/ 2>&1 | grep "E:"
    echo "[ $FILE ]: Instalando ..."
sudo dpkg -i $FILE 2>&1 | grep "E:"
    echo "[ ]: Configurando ..."
cp /usr/share/java/mysql-connector-java-*.jar $DIR_GUAC_LIB/mysql-connector.jar
  echo "[ $FILE ]: OK!"
fi
echo "[ mysql-connector-j_*_all.deb ]: OK!"
sleep 2

echo
echo "[ guacamole.war ]"
FILE=$DIR_GUAC_DOWNLOAD/guacamole-*.war
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ $FILE ]: Baixando ..."
wget $URI_DOWNLOAD_WAR -P $DIR_GUAC_DOWNLOAD/ 2>&1 | grep "E:"
    echo "[ ]: Configurando ..."
cp $FILE $DIR_GUAC/guacamole.war
    sleep 2
  echo "[ $FILE ]: OK!"    
fi
echo "[ guacamole.war ]: OK!"
sleep 2

echo
echo "[ TOMCAT$TOMCAT_VERSION ]"
GUAC_VARIABLE="GUACAMOLE_HOME=$DIR_GUAC"
TOMCAT_FILE="/etc/default/tomcat$TOMCAT_VERSION"

systemctl enable --now tomcat$TOMCAT_VERSION 2>&1 | grep "E:"

if grep $GUAC_VARIABLE $TOMCAT_FILE > /dev/null
  then
  echo "[ $GUAC_VARIABLE ]: OK"
  else
  echo "[ ]: Configurando ..."
echo "$GUAC_VARIABLE" > /etc/default/tomcat$TOMCAT_VERSION
  sleep 2
  echo "[ $GUAC_VARIABLE ]: OK"
fi
sleep 2

FILE=/var/lib/tomcat$TOMCAT_VERSION/webapps/guacamole.war
if [ -e $FILE ];
  then
  echo "[ $FILE ]: OK!"
  else
  echo "[ ]: Configurando ..."
ln -s $DIR_GUAC/guacamole.war /var/lib/tomcat$TOMCAT_VERSION/webapps
sleep 2
  echo "[ $FILE ]: OK!"
fi
sleep 2

DIR=/usr/share/tomcat$TOMCAT_VERSION/.guacamole
if [ -d $DIR ];
  then
  echo "[ $DIR ]: OK!"
  else
  echo "[ ]: Configurando ...."
ln -s $DIR_GUAC $DIR
sleep 2
  echo "[ $DIR ]: OK!"
fi
echo "[ TOMCAT$TOMCAT_VERSION ]: OK!"
sleep 2

echo
echo "[ SSL ]"
FILE=$DIR_GUAC_SSL/key.pem
if [ -e $FILE ];
  then
  ls -l $DIR_GUAC_SSL
  echo "[ $FILE ]: OK!"
  else
  echo "[ ]: Configurando ...."
openssl req -x509 -newkey rsa:4096 -keyout $DIR_GUAC_SSL/key.pem -out $DIR_GUAC_SSL/cert.pem -sha256 -days 3650 -nodes -subj "/C=BR/ST=Parana/L=Curitiba/O=ApacheGuacamoleServer/OU=GuacamoleServer/CN=127.0.0.1" 2>&1 | grep "E:"
  ls -l $DIR_GUAC_SSL
  echo "[ $FILE ]: OK!"
fi
echo "[ SSL ]: OK!"
sleep 2

echo
echo "[ NGINX ]"
FILE=/etc/nginx/sites-available/guacamole
if [ -e $FILE ];
  then
    echo "[ $FILE ]: OK!"
  else
    echo "[ ]: Configurando ...."

sleep 2
cat > $FILE << 'EOF'
server {
  listen 80;
  server_name HOST_IP;
  return 301 https://$host$request_uri;
}
server  {
  listen 443 ssl;
  server_name  HOST_IP;

  root /var/www/html;
  index index.html;
  access_log /var/log/nginx/guacamole-access.log;
  error_log /var/log/nginx/guacamole-error.log;

  #ssl on;
  ssl_certificate DIR_GUAC_SSL/cert.pem;
  ssl_certificate_key  DIR_GUAC_SSL/key.pem;
  #rewrite ^ https://$server_name$request_uri? permanent;
  
  location  / {
    proxy_buffering  off;
    proxy_pass  http://127.0.0.1:8080/guacamole/;
    proxy_http_version  1.1;
    proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header  Upgrade $http_upgrade;
    proxy_set_header  Connection $http_connection;
    access_log  off;
    #try_files $uri $uri/ =404;
  }
  location /.well-known/ {
    allow all;
    root /var/www/html;
  }
}
EOF
echo "[ $FILE ]: OK!"

sleep 2
sudo sed -i "s|HOST_IP|$HOST_IP|g" /etc/nginx/sites-available/guacamole
echo "[ $HOST_IP ]: OK!"

sleep 2
sudo sed -i "s|DIR_GUAC_SSL|$DIR_GUAC_SSL|g" /etc/nginx/sites-available/guacamole
echo "[ $DIR_GUAC_SSL ]: OK!"

sleep 2
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/guacamole /etc/nginx/sites-enabled/
ls -l /etc/nginx/sites-enabled/
echo "[ NGINX - enable]: OK!"
fi
echo "[ NGINX ]: OK!"
sleep 2

##########################################
# CORREÇÃO DE FALHA DE LOGIN RDP WINDOWS #
##########################################
echo
echo "[ Correção: Falha de Login RDP Windows ]"
if grep User=root /etc/systemd/system/guacd.service > /dev/null
  then
  echo "echo "[ Correção: Falha de Login RDP Windows ]: Correção Aplicada!"
  else
  echo "[ Correção: Falha de Login RDP Windows ]: Aplicando correção ..."
cp /etc/systemd/system/guacd.service /etc/systemd/system/guacd.service.bkp
sed -i "s/User=daemon/User=root/g" /etc/systemd/system/guacd.service
echo "echo "[ Correção: Falha de Login RDP Windows ]: OK!"
fi
sleep 2

systemctl daemon-reload
systemctl restart tomcat"$TOMCAT_VERSION" 2>&1 | grep "E:"
systemctl restart guacd
systemctl enable nginx 2>&1 | grep "E:"
sudo nginx -t
systemctl restart nginx

echo 
echo "Instalação concluída!"
echo
echo "---------------------------------------------------------"
echo "Acesse via broswer https://$(hostname -I | cut -d ' ' -f1)"
echo
echo "Usuario: guacadmin"
echo "Senha: guacadmin"
echo "---------------------------------------------------------"
echo
