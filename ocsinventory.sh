apt install -y build-essential sudo wget git curl perl make cmake gcc unzip gnupg systemd-timesyncd ca-certificates

apt install -y net-tools pciutils smartmontools read-edid nmap

apt install -y php-zip php-pclzip php-gd php-curl php-json php-mbstring php-xml php-mysql

apt_dist=ocsinventory

dist_codenome=$(cat /etc/*release* | grep CODENAME | cut -d "=" -f 2)
dist_id=$(cat /etc/issue | cut -d ' ' -f1 | tr 'A-Z' 'a-z')

keyring_gpg_path=/usr/share/keyrings/$apt_dist.gpg

uri_gpg=http://deb.ocsinventory-ng.org/pubkey.gpg
uri_repo=http://deb.ocsinventory-ng.org/$dist_id/

curl -fsSL $uri_gpg | sudo gpg --dearmor -o $keyring_gpg_path

cat >> /etc/apt/sources.list.d/$apt_dist.list << EOL
deb [signed-by=$keyring_gpg_path] $uri_repo $dist_codenome main
EOL

apt update

apt install -y libapache2-mod-perl2 \
libapache-dbi-perl \
libapache-db-perl \
libapache2-mod-php \
libxml-simple-perl \
libxml-perl \
libdbd-mysql-perl \
libnet-ip-perl \
libsoap-lite-perl \
libsoap-wsdl-perl \
libio-compress-perl \
libcrypt-ssleay-perl \
libnet-snmp-perl \
libproc-pid-file-perl \
libproc-daemon-perl \
libnet-netmask-perl \
libarchive-zip-perl \
libmojolicious-perl \
libswitch-perl \
libyaml-perl \
libghc-libyaml-dev \
apache2-dev \
libplack-handler-anyevent-fcgi-perl

yes | cpan -i YAML
cpan -i XML::Entities
cpan -i Apache2::SOAP
cpan -i SOAP::Transport::HTTP

sudo apt install -y ocsinventory

chown -Rv www-data.www-data /var/lib/ocsinventory-reports

sed -i 's/OCS_OPT_GENERATE_OCS_FILES_SNMP 0/OCS_OPT_GENERATE_OCS_FILES_SNMP 0 \
  # PerlSetEnv SNMP_LINK_TAG 0\
  PerlSetEnv OCS_OPT_SNMP_LINK_TAG 0/g' /etc/apache2/conf-enabled/z-ocsinventory-server.conf

echo "ServerName localhost" >> /etc/apache2/apache2.conf

systemctl reload apache2.service
systemctl restart apache2

echo
sudo apache2ctl -t
echo
echo
echo "Instalação Concluída"
echo
echo "Acesse via broswer http://$(hostname -I | head -n1 | cut -f1 -d' ')/ocsreports"
echo
echo "Usuario: admin"
echo "Senha: admin"
echo

