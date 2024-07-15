OCS_VERSION=2.12.2
OCS_AGENT_VERSION=2.10.0

OCS_DB_NAME='"ocs_db"'
OCS_DB_PORT='"3306"'
OCS_DB_USER='"ocs_user"'
OCS_DB_PASSWORD='"ocs_password"'

OCS_PATH=/var/www/OCSNG_UNIX_SERVER-$OCS_VERSION

HOST_IP=$(hostname -I | head -n1 | cut -f1 -d' ')

apt install -y build-essential sudo wget git curl perl make cmake gcc unzip

apt install -y mariadb-server php apache2-dev

apt install -y net-tools pciutils smartmontools read-edid nmap

apt install -y php-zip php-pclzip php-gd php-curl php-json php-mbstring php-xml php-mysql

apt install -y libapache2-mod-perl2 \
libapache-dbi-perl \
libapache-db-perl \
libapache2-mod-php \
libxml-simple-perl \
libxml-perl \
libdbd-mysql-perl \
libnet-ip-perl \
libsoap-lite-perl \
libio-compress-perl \
libcrypt-ssleay-perl \
libnet-snmp-perl \
libproc-pid-file-perl \
libproc-daemon-perl \
libnet-netmask-perl \
libarchive-zip-perl \
libmojolicious-perl \
libswitch-perl \
libplack-handler-anyevent-fcgi-perl

PHP_VERSION=$(php -v | head -n1 | cut -d " " -f 2 | cut -d "." -f 1,2)

PHP_PATH=$(php --ini | grep "Path" | cut -d ':' -f 2 | tr -d ' ')

PHP_FILE=$PHP_PATH/php.ini

sudo sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/g' $PHP_FILE
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 512M/g' $PHP_FILE
sudo sed -i 's/file_uploads = On/file_uploads = On/g' $PHP_FILE
sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/g' $PHP_FILE
sudo sed -i 's/max_execution_time = 30/max_execution_time = -1/g' $PHP_FILE
sudo sed -i 's/max_input_time = 60/max_input_time = -1/g' $PHP_FILE
sudo sed -i 's/post_max_size = 8M/post_max_size = 512M/g' $PHP_FILE

cat $PHP_FILE | grep "date.timezone ="
cat $PHP_FILE | grep "upload_max_filesize ="
cat $PHP_FILE | grep "file_uploads ="
cat $PHP_FILE | grep "memory_limit ="
cat $PHP_FILE | grep "max_execution_time ="
cat $PHP_FILE | grep "max_input_time ="
cat $PHP_FILE | grep "post_max_size ="

cat >> /opt/ocs_config.sql << EOL
CREATE DATABASE $OCS_DB_NAME;
CREATE USER '$OCS_DB_USER'@'localhost' IDENTIFIED BY '$OCS_DB_PASSWORD';
GRANT ALL PRIVILEGES on $OCS_DB_NAME.* TO '$OCS_DB_USER'@'localhost';
EOL

sudo sed -i 's/"//g' /opt/ocs_config.sql

mysql -u root < /opt/ocs_config.sql

wget -P /opt/ https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/$OCS_VERSION/OCSNG_UNIX_SERVER-$OCS_VERSION.tar.gz
tar xvf /opt/OCSNG_UNIX_SERVER-$OCS_VERSION.tar.gz -C /var/www/

cp $OCS_PATH/./setup.sh $OCS_PATH/./setup.sh.bkp

sudo sed -i 's|DB_SERVER_HOST="${DB_SERVER_HOST:-localhost}"|DB_SERVER_HOST="localhost"|g' $OCS_PATH/./setup.sh

sudo sed -i 's|DB_SERVER_PORT="${DB_SERVER_PORT:-3306}"|DB_SERVER_PORT=OCS_DB_PORT|g' $OCS_PATH/./setup.sh
sudo sed -i 's|DB_SERVER_USER="${DB_SERVER_USER:-ocs}"|DB_SERVER_USER=OCS_DB_USER|g' $OCS_PATH/./setup.sh
sudo sed -i 's|DB_SERVER_PWD="${DB_SERVER_PWD:-ocs}"|DB_SERVER_PWD=OCS_DB_PASSWORD|g' $OCS_PATH/./setup.sh

sudo sed -i "s|DB_SERVER_PORT=OCS_DB_PORT|DB_SERVER_PORT="$OCS_DB_PORT"|g" $OCS_PATH/./setup.sh
sudo sed -i "s|DB_SERVER_USER=OCS_DB_USER|DB_SERVER_USER="$OCS_DB_USER"|g" $OCS_PATH/./setup.sh
sudo sed -i "s|DB_SERVER_PWD=OCS_DB_PASSWORD|DB_SERVER_PWD="$OCS_DB_PASSWORD"|g" $OCS_PATH/./setup.sh

cd $OCS_PATH

export APACHE_BIN=/usr/sbin/apache2ctl
export APACHE_BIN_FOUND=/usr/sbin/apache2ctl

echo "y" | sh ./setup.sh

cp /etc/apache2/conf-available/z-ocsinventory-server.conf /etc/apache2/conf-available/z-ocsinventory-server.conf.bkp
cp /etc/apache2/conf-available/zz-ocsinventory-restapi.conf /etc/apache2/conf-available/zz-ocsinventory-restapi.conf.bkp

OCS_DB_NAME=$(echo $OCS_DB_NAME | cut -d '"' -f2)
OCS_DB_PORT=$(echo $OCS_DB_PORT | cut -d '"' -f2)
OCS_DB_USER=$(echo $OCS_DB_USER | cut -d '"' -f2)
OCS_DB_PASSWORD=$(echo $OCS_DB_PASSWORD | cut -d '"' -f2)

PTH_ZZ_OCS_RESTAPI=/etc/apache2/conf-available/zz-ocsinventory-restapi.conf

cp $PTH_ZZ_OCS_RESTAPI $PTH_ZZ_OCS_RESTAPI.bkp

sudo sed -i "s|$ENV{OCS_DB_HOST} = 'localhost';;|$ENV{OCS_DB_HOST} = 'localhost';|" $PTH_ZZ_OCS_RESTAPI
sudo sed -i "s|$ENV{OCS_DB_PORT} = '3306';|$ENV{OCS_DB_PORT} = '$OCS_DB_PORT';|" $PTH_ZZ_OCS_RESTAPI
sudo sed -i "s|$ENV{OCS_DB_NAME} = 'ocsweb';|$ENV{OCS_DB_LOCAL} = '$OCS_DB_NAME';|" $PTH_ZZ_OCS_RESTAPI
sudo sed -i "s|$ENV{OCS_DB_LOCAL} = 'ocsweb';|$ENV{OCS_DB_LOCAL} = '$OCS_DB_NAME';|" $PTH_ZZ_OCS_RESTAPI
sudo sed -i "s|$ENV{OCS_DB_USER} = 'ocs';|$ENV{OCS_DB_USER} = '$OCS_DB_USER';|" $PTH_ZZ_OCS_RESTAPI
sudo sed -i "s|$ENV{OCS_DB_PWD} = 'ocs';|$ENV{OCS_DB_PWD} = '$OCS_DB_PASSWORD';|" $PTH_ZZ_OCS_RESTAPI
sudo sed -i "s|$ENV{OCS_DB_SSL_ENABLED} = 0;|$ENV{OCS_DB_SSL_ENABLED} = 0;|" $PTH_ZZ_OCS_RESTAPI

PTH_Z_OCS=/etc/apache2/conf-available/z-ocsinventory-server.conf

sudo sed -i "s|PerlSetEnv OCS_DB_HOST localhost|PerlSetEnv OCS_DB_HOST localhost|" $PTH_Z_OCS
sudo sed -i "s|PerlSetEnv OCS_DB_PORT 3306|PerlSetEnv OCS_DB_PORT $OCS_DB_PORT|" $PTH_Z_OCS
sudo sed -i "s|PerlSetEnv OCS_DB_NAME ocsweb|PerlSetEnv OCS_DB_NAME $OCS_DB_NAME|" $PTH_Z_OCS
sudo sed -i "s|PerlSetEnv OCS_DB_LOCAL ocsweb|PerlSetEnv OCS_DB_LOCAL $OCS_DB_NAME|" $PTH_Z_OCS
sudo sed -i "s|PerlSetEnv OCS_DB_USER ocs|PerlSetEnv OCS_DB_USER $OCS_DB_USER|" $PTH_Z_OCS
sudo sed -i "s|PerlSetVar OCS_DB_PWD ocs|PerlSetVar OCS_DB_PWD $OCS_DB_PASSWORD|" $PTH_Z_OCS
sudo sed -i "s|PerlSetEnv OCS_OPT_ACCEPT_TAG_UPDATE_FROM_CLIENT 0|PerlSetEnv OCS_OPT_ACCEPT_TAG_UPDATE_FROM_CLIENT 1|" $PTH_Z_OCS

APACHE_RUN_USER=$(cat /etc/apache2/envvars | grep APACHE_RUN_USER | cut -d '=' -f 2)
APACHE_RUN_GROUP=$(cat /etc/apache2/envvars | grep APACHE_RUN_GROUP | cut -d '=' -f 2)
APACHE_PID_FILE=$(cat /etc/apache2/envvars | grep APACHE_PID_FILE | cut -d '=' -f 2| tr -d '$SUFFIX')
APACHE_LOG_DIR=$(cat /etc/apache2/envvars | grep APACHE_LOG_DIR | cut -d '=' -f 2| tr -d '$SUFFIX')
APACHE_PATH_FILE=/etc/apache2/apache2.conf

sed -i 's|${APACHE_RUN_USER}|APACHE_RUN_USER|g' $APACHE_PATH_FILE
sed -i 's|${APACHE_RUN_GROUP}|APACHE_RUN_GROUP|g' $APACHE_PATH_FILE
sed -i 's|${APACHE_PID_FILE}|APACHE_PID_FILE|g' $APACHE_PATH_FILE
sed -i 's|${APACHE_LOG_DIR}|APACHE_LOG_DIR|g' $APACHE_PATH_FILE

sed -i "s|APACHE_RUN_USER|$APACHE_RUN_USER|g" $APACHE_PATH_FILE
sed -i "s|APACHE_RUN_GROUP|$APACHE_RUN_GROUP|g" $APACHE_PATH_FILE
sed -i "s|APACHE_PID_FILE|$APACHE_PID_FILE|g" $APACHE_PATH_FILE
sed -i "s|APACHE_LOG_DIR|$APACHE_LOG_DIR|g" $APACHE_PATH_FILE

sed -i 's/OCS_OPT_GENERATE_OCS_FILES_SNMP 0/OCS_OPT_GENERATE_OCS_FILES_SNMP 0 \
  # PerlSetEnv SNMP_LINK_TAG 0\
  PerlSetEnv OCS_OPT_SNMP_LINK_TAG 0/g' /etc/apache2/conf-enabled/z-ocsinventory-server.conf

echo "ServerName localhost" >> /etc/apache2/apache2.conf

rm /etc/apache2/sites-enabled/000-default.conf
rm /etc/apache2/conf-enabled/other-vhosts-access-log.conf

ln -s /etc/apache2/conf-available/ocsinventory-reports.conf /etc/apache2/conf-enabled/ocsinventory-reports.conf
ln -s /etc/apache2/conf-available/z-ocsinventory-server.conf /etc/apache2/conf-enabled/z-ocsinventory-server.conf
ln -s /etc/apache2/conf-available/zz-ocsinventory-restapi.conf /etc/apache2/conf-enabled/zz-ocsinventory-restapi.conf

sudo a2enconf ocsinventory-reports
sudo a2enconf z-ocsinventory-server
sudo a2enconf zz-ocsinventory-restapi
sudo a2enmod perl

chown -R www-data:www-data /var/lib/ocsinventory-reports
chown -R www-data:www-data /var/run/apache2

systemctl restart apache2
systemctl reload apache2.service

echo
echo "Instalação Concluída"
echo
echo "Acesse via broswer http://$HOST_IP/ocsreports"
echo
echo "Informe os dados configurados na instalação:"
echo
echo "Nome da base de dados: $OCS_DB_NAME"
echo "Porta MySQL : 3306"
echo "Servidor Mysql: localhost"
echo "Usuário Mysql: $OCS_DB_USER"
echo "Senha Mysql: $OCS_DB_PASSWORD"
echo "Habilitar SSL: Não"
echo
echo
echo "Usuario: admin"
echo "Senha: admin"
echo

# yes | cpan -f XML::Entities
# cpan install XML::Entities
# cpan install YAML
# cpan -f SOAP::Transport::HTTP

# export PERL_MM_USE_DEFAULT=1
# perl -MCPAN -e 'install Mojolicious'
# perl -MCPAN -e 'install Switch'
# perl -MCPAN -e 'install Plack'
# perl -MCPAN -e 'install Net::IP'
# perl -MCPAN -e 'install Net::IP'
# perl -MCPAN -e 'install Net::SNMP'
# perl -MCPAN -e 'install Net::Netmask'
# perl -MCPAN -e 'install XML::Simple'
# perl -MCPAN -e 'install Digest::MD5'
# perl -MCPAN -e 'install Data::UUID'
# perl -MCPAN -e 'install Mac::SysProfile'
# perl -MCPAN -e 'install Crypt::SSLeay'
# perl -MCPAN -e 'install LWP::Protocol::https'
# perl -MCPAN -e 'install Proc::Daemon'
# perl -MCPAN -e 'install Proc::PID::File'
# perl -MCPAN -e 'install Nmap::Parser'
# perl -MCPAN -e 'install Module::Install'
# perl -MCPAN -e 'install Parse::EDID'
# perl -MCPAN -e 'Archive::Zip'
# set PERL_MM_USE_DEFAULT

# cpan -f Archive::Zip ## sudo apt-get install -y libarchive-zip-perl
# cpan -f Mojolicious::Lite ## sudo apt-get install -y libmojolicious-perl
# cpan -f Switch ## sudo apt-get install -y libswitch-perl
# cpan -f Plack::Handler ## sudo apt-get install -y libplack-handler-anyevent-fcgi-perl
