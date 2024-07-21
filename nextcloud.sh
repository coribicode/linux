NC_DB_NAME=nextcloud_db
NC_DB_USER=nextcloud_db_user
NC_DB_PASS=nextcloud_db_user_pass

NC_USER_NAME=admin
NC_USER_PASS=password

HOST_IP=$(hostname -I | head -n1 | cut -f1 -d' ')

apt install -y sudo wget unzip bzip2  lbzip2
apt install -y apache2 openssl
apt install -y php libapache2-mod-php php-mysql php-common php-gd php php-fpm php-curl php-cli php-xml php-json php-intl php-pear php-imagick php-dev php-common php-mbstring php-zip php-soap php-bz2 php-bcmath php-gmp php-apcu libmagickcore-dev php-redis php-memcached

PHP_VERSION=$(php -v | head -n1 | cut -d " " -f 2 | cut -d "." -f 1,2)
DIR_APACHE=/etc/php/*/apache2/php.ini

cp $DIR_APACHE /opt/

sudo sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/g' $DIR_APACHE
sudo sed -i 's/max_execution_time = 30/max_execution_time = 3000/g' $DIR_APACHE
sudo sed -i 's/memory_limit = 128M/memory_limit = 4096M/g' $DIR_APACHE
sudo sed -i 's/post_max_size = 8M/post_max_size = 4096M/g' $DIR_APACHE
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 1024000M/g' $DIR_APACHE
sudo sed -i 's/display_errors = On/display_errors = Off/g' $DIR_APACHE
sudo sed -i 's/output_buffering = 4096/output_buffering = Off/g' $DIR_APACHE
sudo sed -i 's/file_uploads = Off/file_uploads = On/g' $DIR_APACHE
sudo sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/g' $DIR_APACHE
sudo sed -i 's/;zend_extension/zend_extension/g' $DIR_APACHE
echo
sudo sed -i 's/;opcache.enable=1/opcache.enable=1/g' $DIR_APACHE
sudo sed -i 's/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=32/g' $DIR_APACHE
sudo sed -i 's/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=10000/g' $DIR_APACHE
sudo sed -i 's/;opcache.memory_consumption=128/opcache.memory_consumption=512/g' $DIR_APACHE
sudo sed -i 's/;opcache.save_comments=1/opcache.save_comments=1/g' $DIR_APACHE
sudo sed -i 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=1/g' $DIR_APACHE
sudo sed -i 's/opcache.memory_consumption=128/opcache.memory_consumption=1024/g' $DIR_APACHE
sudo sed -i 's/opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=1024/g' $DIR_APACHE
echo

sudo sed -i 's|;clear_env|clear_env|g' /etc/php/$PHP_VERSION/fpm/pool.d/www.conf

echo 'apc.enable_cli = 1' >> /etc/php/$PHP_VERSION/cli/php.ini
echo 'apc.enable_cli=1' >> /etc/php/$PHP_VERSION/mods-available/apcu.ini
echo 'apc.shm_size=512M' >> /etc/php/$PHP_VERSION/mods-available/apcu.ini


sleep 2

sudo apt install -y mariadb-server

cat >> /opt/nextcloud_config.sql << EOL
CREATE DATABASE $NC_DB_NAME;
CREATE USER $NC_DB_USER@localhost IDENTIFIED BY '$NC_DB_PASS';
GRANT ALL PRIVILEGES ON $NC_DB_NAME.* TO $NC_DB_USER@localhost;
FLUSH PRIVILEGES;
EOL

mysql -u root < /opt/nextcloud_config.sql

wget -P /opt/ https://download.nextcloud.com/server/releases/latest.tar.bz2
tar xvf /opt/latest.tar.bz2 -C /var/www/html/
sudo mkdir -p /var/www/html/nextcloud/data
sudo chmod -R 755 /var/www/html/nextcloud/
sudo chown -R www-data:www-data /var/www/html/nextcloud/

date

cat >> /etc/apache2/sites-available/nextcloud.conf << EOF
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/nextcloud/
    ServerName HOST_IP
    Redirect permanent / https://HOST_IP/
</VirtualHost>
EOF
sudo sed -i "s/HOST_IP/$HOST_IP/g" /etc/apache2/sites-available/nextcloud.conf

cat >> /etc/apache2/sites-available/nextcloud-ssl.conf << EOF
<VirtualHost *:80>
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
</VirtualHost>

<VirtualHost *:443>
    DirectoryIndex index.html index.php
    ServerAdmin contact@mydomain.com
    DocumentRoot /var/www/html/nextcloud
    ServerName HOST_IP
    ErrorLog /var/log/nextcloud.log
    CustomLog /var/log/nextcloud-access.log combined

    SSLEngine on
    SSLProtocol all
    SSLCertificateFile /etc/ssl/certs/nextcloud/cert.pem
    SSLCertificateKeyFile /etc/ssl/certs/nextcloud/key.pem

    <IfModule mod_headers.c>
      Header always set Strict-Transport-Security "max-age=63072000; preload"
    </IfModule>
    <Directory /var/www/html/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
    </Directory>
</VirtualHost>
EOF

sudo sed -i "s/HOST_IP/$HOST_IP/g" /etc/apache2/sites-available/nextcloud-ssl.conf

mkdir /etc/ssl/certs/nextcloud
openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/certs/nextcloud/key.pem -out /etc/ssl/certs/nextcloud/cert.pem -sha256 -days 3650 -nodes -subj "/C=BR/ST=Parana/L=Curitiba/O=nextcloud/OU=nextcloud/CN=127.0.0.1"

echo "ServerName localhost" >> /etc/apache2/apache2.conf
rm /etc/apache2/sites-enabled/000-default.conf
chown -R www-data:www-data /var/run/apache2
source /etc/apache2/envvars

apt install -y fail2ban
cat >> /etc/fail2ban/filter.d/nextcloud.conf << EOF
[Definition]
_groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
            ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
EOF

cat >> /etc/fail2ban/jail.d/nextcloud.local << EOF
[nextcloud]
backend = auto
enabled = true
port = 80,443
protocol = tcp
filter = nextcloud
maxretry = 3
bantime = 86400
findtime = 43200
logpath = /var/log/nextcloud.log
EOF

sed -i 's|#allowipv6|allowipv6|g' /etc/fail2ban/fail2ban.conf
sed -i 's|%(sshd_log)s|/var/log/sshd.log|g' /etc/fail2ban/jail.conf
touch /var/log/sshd.log

sudo systemctl enable fail2ban.service
sudo service fail2ban restart

apt install -y redis

sudo usermod -a -G redis www-data

sed -i 's|# unixsocketperm 700|unixsocketperm 770|g' /etc/redis/redis.conf
sed -i 's|# unixsocket|unixsocket|g' /etc/redis/redis.conf


sudo a2enmod ssl rewrite headers
sudo a2ensite nextcloud-ssl.conf

sudo systemctl restart redis-server
sudo systemctl restart apache2
sudo service fail2ban reload
sudo service fail2ban restart

## https://docs.nextcloud.com/server/29/admin_manual/installation/command_line_installation.html
sudo -u www-data php /var/www/html/nextcloud/occ  maintenance:install \
--database='mysql' --database-name="$NC_DB_NAME" \
--database-user="$NC_DB_USER" --database-pass="$NC_DB_PASS" \
--admin-user="$NC_USER_NAME" --admin-pass="$NC_USER_PASS"

sed -i "s|0 => 'localhost|0 => '$HOST_IP|g" /var/www/html/nextcloud/config/config.php

## FIXES
sudo sed -i 's|);||g' $DIR_NC_CONFIG

cat >> $DIR_NC_CONFIG << EOL
  'default_phone_region' => 'BR',
  'default_language' => 'pt_BR',
  'logtimezone' => 'America/Sao_Paulo',
  'filelocking.enabled' => true,
  'memcache.local' => '\OC\Memcache\APCu',
  'memcache.distributed' => '\OC\Memcache\Redis',
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => [
     'host' => '/run/redis/redis-server.sock',
     'port' => 0,
     'timeout' => 0.0,
  ],
  'mail_smtpmode' => 'smtp',
  'mail_smtphost' => 'smtp.example.com',
  'mail_smtpport' => 425,
  'mail_smtpsecure'   => 'ssl',
  'mail_smtpauth' => false,
  'mail_smtpname' => '',
  'mail_smtppassword' => '',
  'mail_smtptimeout'  => 30,
  'mail_smtpdebug' => false,
  'loglevel' => 2,
  'mail_domain' => 'example.com',
  'enable_previews'=> true,
  'enabledPreviewProviders'=> [
    'OC\\Preview\\TXT',
    'OC\\Preview\\MarkDown',
    'OC\\Preview\\OpenDocument',
    'OC\\Preview\\PDF',
    'OC\\Preview\\MSOffice2003',
    'OC\\Preview\\MSOfficeDoc',
    'OC\\Preview\\Image',
    'OC\\Preview\\Photoshop',
    'OC\\Preview\\TIFF',
    'OC\\Preview\\SVG',
    'OC\\Preview\\Font',
    'OC\\Preview\\MP3',
    'OC\\Preview\\Movie',
    'OC\\Preview\\MKV',
    'OC\\Preview\\MP4',
    'OC\\Preview\\AVI',
    'OC\\Preview\\HEIC'
    ]
  );
EOL

chmod -R 755 /var/www/html/nextcloud
chown -R www-data:www-data /var/www/html/nextcloud

sudo -u www-data php /var/www/html/nextcloud/occ config:system:set maintenance_window_start --type=integer --value=1
sudo -u www-data php --define apc.enable_cli=1 /var/www/html/nextcloud/occ maintenance:repair
sudo -u www-data truncate /var/www/html/nextcloud/data/nextcloud.log --size 0
sudo -u www-data php /var/www/html/nextcloud/occ integrity:check-core
sudo -u www-data php /var/www/html/nextcloud/occ files:scan --all
#sudo -u www-data php /var/www/html/nextcloud/occ files:cleanup
#sudo -u www-data php /var/www/html/nextcloud/occ maintenance:repair

echo
echo "sudo apachectl configtest"
echo "----------------------------------------"
sudo apachectl configtest
echo
echo "sudo apachectl -t"
echo "----------------------------------------"
sudo apachectl -t
echo
echo "sudo apache2ctl -t"
echo "----------------------------------------"
sudo apache2ctl -t
echo
echo "sudo service fail2ban status"
echo "----------------------------------------"
sudo service fail2ban status | grep -E "Loaded|Active"
echo
echo "sudo service redis status"
echo "----------------------------------------"
sudo service redis status | grep -E "Loaded|Active"
echo
#ps ax | grep redis
echo "Verificando arquivos de instalação do Nextcloud"
echo "----------------------------------------"
sudo -u www-data truncate /var/www/html/nextcloud/data/nextcloud.log --size 0 # Limpa o Log
sudo -u www-data php /var/www/html/nextcloud/occ integrity:check-core # Verifica a integridade do sistema
sudo -u www-data php /var/www/html/nextcloud/occ files:scan --all # Procura erros de configuração no sistema
echo
echo
echo "Instalação Concluída!"
echo "----------------------------------------"
echo
echo "Acesse via broswer https://$HOST_IP:    "
echo "----------------------------------------"
echo 
echo "Usuário: $NC_USER_NAME"
echo "Senha: $NC_USER_PASS"
echo
date
echo
ls -ll /var/www/html/nextcloud/config/config.php

#echo "DNS_CNAME"
#echo "----------------------------------------"
#cat /var/www/html/nextcloud/lib/private/Http/Client/DnsPinMiddleware.php | grep DNS_CNAME
