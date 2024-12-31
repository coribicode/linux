DOMAIN='VIRTUALEASY.LANNET'
DOMAIN_PASS='Passw0rd$2'
DOMAIN_IP='192.168.0.119'
RESOLV_FILE='/etc/resolvconf/resolv.conf.d/head'
#HOSTNAME_FQDN=$(cat /etc/hostname | sed -e 's/\(.*\)/\L\1/').$(echo $DOMAIN | sed -e 's/\(.*\)/\L\1/')
HOSTNAME_FQDN=vm001.$(echo $DOMAIN | sed -e 's/\(.*\)/\L\1/')

apt install -y curl sudo wget git
debian_repository=https://raw.githubusercontent.com/davigalucio/linux/main/debian_repository.sh
curl -fsSL $debian_repository | sh

apt install -y lxde-core xrdp 

url_sh=https://raw.githubusercontent.com/davigalucio/linux/main/fix-blackscreen.sh
curl -fsSL $url_sh | sh
#sudo reboot

sudo apt install -y resolvconf
systemctl start resolvconf
systemctl enable resolvconf
#systemctl status resolvconf


if grep "$DOMAIN" $RESOLV_FILE > /dev/null
then
echo "[ Dominio DNS ]: OK!"
else
echo "[ Dominio DNS  ]: Configurando ... "
sleep 5
cp $RESOLV_FILE $RESOLV_FILE.bkp
cat >> $RESOLV_FILE << EOL
nameserver $DOMAIN_IP
domain $(echo $DOMAIN | sed -e 's/\(.*\)/\L\1/')
search $(echo $DOMAIN | sed -e 's/\(.*\)/\L\1/')
nameserver 8.8.8.8
nameserver 8.8.4.4
EOL
fi

resolvconf --enable-updates
resolvconf -u

## https://medium.com/@aurelson/debian-integration-with-ad-5ffdb8be0a19
hostnamectl set-hostname $HOSTNAME_FQDN
hostnamectl
apt -y install sudo realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit dnsutils
#apt -y install realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit
sudo realm discover $DOMAIN
echo $DOMAIN_PASS | realm join -U administrator $DOMAIN

if grep "pam_mkhomedir.so skel=/etc/skel umask=077" /etc/pam.d/common-session > /dev/null
then
echo "[ PAM_MKHOMEDIR ]: OK!"
else
echo "[ PAM_MKHOMEDIR ]:  Configurando ..."
cat >> /etc/pam.d/common-session << EOL
session optional        pam_mkhomedir.so skel=/etc/skel umask=077
EOL
fi

cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf.bkp

if grep "use_fully_qualified_names = False" /etc/sssd/sssd.conf > /dev/null
then
echo "[ SSSD FQDN ]: OK!"
else
echo "[ SSSD FQDN  ]:  Configurando ..."
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False'/g /etc/sssd/sssd.conf
fi

#if grep "ldap_id_mapping = False" /etc/sssd/sssd.conf > /dev/null
#then
#echo "[ SSSD FQDN ]: OK!"
#else
#echo "[ SSSD FQDN  ]:  Configurando ..."
#sed -i 's/ldap_id_mapping = True/ldap_id_mapping = False'/g /etc/sssd/sssd.conf
#fi

if grep "ldap_user_uid_number" /etc/sssd/sssd.conf > /dev/null
then
echo "[ SSSD UID ]: OK!"
else
echo "[ SSSD UID ]: Configurando ..."
cat >> /etc/sssd/sssd.conf << EOL
#ldap_user_uid_number = uidNumber
#ldap_user_gid_number = gidNumber
ad_gpo_ignore_unreadable = True
ad_gpo_access_control = permissive
EOL
fi

pam-auth-update --enable mkhomedir
mkdir -p /var/lib/sss/gpo_cache/$DOMAIN
chown -R sssd:sssd /var/lib/sss/gpo_cache

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bkp
sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

dc_grp_admins=grp-admins
cat > /etc/ssh/sshd_config.d/grp-$dc_grp_admins.conf << EOL 
AllowGroups Domain $dc_grp_admins sudo $USER administrator Administrator
EOL


systemctl restart sssd

getent passwd administrator
