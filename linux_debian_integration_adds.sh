###########################################################################
DOMAIN=EMPRESA.NETLAN        # NOME DO SEU DOMINIO
DOMAIN_IP='192.168.0.119'    # IP DO SERVIDOR LDAP
DOMAIN_PASS='Passw0rd$2'     # SENHA DO usuário 'administrator' DO DOMINIO
hostname=adm001vm            # NOME DA MAQUINA LOCAL
###########################################################################
RESOLV_FILE='/etc/resolvconf/resolv.conf.d/head'
HOSTNAME_FQDN=$(echo $hostname.$DOMAIN | sed -e 's/\(.*\)/\L\1/')

apt install -y curl 2>/dev/null | grep "E:"
curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh 2>/dev/null | grep "E:"

INSTALLER="install.sh"
PACKAGES_DEPENDECES="sudo realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit dnsutils resolvconf"
package_list="$PACKAGES_DEPENDECES"

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

hostnamectl set-hostname $HOSTNAME_FQDN
hostnamectl

realm discover $DOMAIN
echo $DOMAIN_PASS | realm join -U administrator $DOMAIN

pam-auth-update --enable mkhomedir
mkdir -p /var/lib/sss/gpo_cache/$DOMAIN
chown -R sssd:sssd /var/lib/sss/gpo_cache

echo "-------------------------------------"
cp /etc/pam.d/common-session /etc/pam.d/common-session.bkp
if grep "pam_mkhomedir.so skel=/etc/skel umask=077" /etc/pam.d/common-session > /dev/null
then
echo "[ PAM_MKHOMEDIR ]: OK!"
else
echo "[ PAM_MKHOMEDIR ]:  Configurando ..."
cat >> /etc/pam.d/common-session << EOL
session optional        pam_mkhomedir.so skel=/etc/skel umask=077
EOL
sleep 3
echo "[ PAM_MKHOMEDIR ]:  OK!"
fi
echo "-------------------------------------"
cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf.bkp
if grep "use_fully_qualified_names = False" /etc/sssd/sssd.conf > /dev/null
then
echo "[ SSSD FQDN ]: OK!"
else
echo "[ SSSD FQDN  ]:  Configurando ..."
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False'/g /etc/sssd/sssd.conf
sleep 3
echo "[ SSSD FQDN  ]:  OK!"
fi
echo "-------------------------------------"
if grep "ldap_id_mapping = False" /etc/sssd/sssd.conf > /dev/null
then
echo "[ SSSD FQDN ]: OK!"
else
echo "[ SSSD FQDN  ]:  Configurando ..."
sed -i 's/ldap_id_mapping = True/ldap_id_mapping = False'/g /etc/sssd/sssd.conf
sleep 3
echo "[ SSSD FQDN  ]:  OK!"
fi
echo "-------------------------------------"
if grep "ldap_user_uid_number" /etc/sssd/sssd.conf > /dev/null
then
echo "[ SSSD UID ]: OK!"
else
echo "[ SSSD UID ]: Configurando ..."
cat >> /etc/sssd/sssd.conf << EOL
ldap_user_uid_number = uidNumber
ldap_user_gid_number = gidNumber
ad_gpo_ignore_unreadable = True
ad_gpo_access_control = permissive
EOL
sleep 3
echo "[ SSSD UID ]: OK!"
fi
echo "-------------------------------------"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bkp
if grep "UsePAM no" /etc/ssh/sshd_config > /dev/null
then
echo "[ SSHD UsePAM ]: OK!"
else
echo "[ SSHD UsePAM ]: Configurando..."
sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
sleep 3
echo "[ SSHD UsePAM ]: OK!"
fi
echo "-------------------------------------"

dc_grp_admins=grp-admins
cat > /etc/ssh/sshd_config.d/grp-$dc_grp_admins.conf << EOL 
AllowGroups Domain $dc_grp_admins sudo $USER administrator Administrator
EOL

systemctl restart sssd

getent passwd administrator
