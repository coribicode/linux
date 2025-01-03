#!/bin/sh
clear
pergunta(){
 while true; do
  echo
  echo "======== Bem-vindo a Instalação do SAMBA4 ========="
  echo
  read -p "Informe o nome para este SERVIDOR [ex: SRVLDAP001 ]: " servername
  read -p "Informe o nome de DOMINIO [ ex: EMPRESA.NETLAN ]: " dominio
  stty -echo
  echo "Informe a senha do administrator@$dominio"
  read -p "Senha: " senha1
  echo
  read -p "Confirme a senha: " senha2
  stty echo
  echo
  if [ "$senha1" = "$senha2" ]; then
   valida
  else
   echo "------------------------------"
   echo "As senhas não coincidem!"
   verifica
  fi
 done
}

verifica(){
 echo
 echo -n "Deseja tentar novamente? (s/n): "
 read resposta
 case $resposta in
  s|S) pergunta ;;
  n|N) exit 0 ;;
  *) echo "Opção Inválida."
     verifica;;
 esac
}
instalar(){
###########################################################################
domain=$dominio        # NOME DO SEU DOMINIO
pass=$senha            # SENHA DO usuário 'administrator' DO DOMINIO
hostname=$servername   # NOME DO SERVIDOR LDAP
###########################################################################

apt install -y curl 2>/dev/null | grep "E:"
curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh 2>/dev/null | grep "E:"

INSTALLER="install.sh"
PACKAGES_DEPENDECES="samba wget net-tools libpam-krb5 krb5-user dnsutils sudo smbclient ntpsec ntpdate cifs-utils libnss-winbind libpam-winbind acl ldap-utils attr ldb-tools smbldap-tools smbios-utils quota"
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
sleep 2

domain_realm=$(echo $domain | sed -e 's/\(.*\)/\L\1/')
domain_name=$(echo $domain | cut -d '.' -f 1)

gateway=$(ip route | grep default | egrep '[0-9\.]{6,}' | awk '{print $3}')

ip4=$(hostname -I | cut -d '.' -f 4 | cut -d ' ' -f 1)
ip3=$(hostname -I | cut -d '.' -f 3 | cut -d ' ' -f 1)
ip2=$(hostname -I | cut -d '.' -f 2 | cut -d ' ' -f 1)
ip1=$(hostname -I | cut -d '.' -f 1 | cut -d ' ' -f 1)

nic=$(ip -4 a | grep $(hostname -I | cut -d ' ' -f 1) | grep -o '[^ ]*$')

hostname=$(echo $hostname.$domain | sed -e 's/\(.*\)/\L\1/')
HOSTNAME=$(echo $hostname | cut -d '.' -f 1 )
hostnamectl set-hostname $hostname

#hostname=$(echo $(hostname).$domain)
#hostname=$(echo $hostname | sed -e 's/\(.*\)/\L\1/')


mv /etc/network/interfaces /etc/network/interfaces.bkp
cat >> /etc/network/interfaces << EOL
source /etc/network/interfaces.d/*
EOL

cat > /etc/network/interfaces.d/$nic << EOL
auto $nic
allow-hotplug $nic
iface $nic inet static
address $(hostname -I | cut -d ' ' -f 1)
netmask 255.255.255.0
broadcast $(hostname -I | cut -d ' ' -f 1 | cut -d '.' -f 1-3).255
gateway $gateway
dns-search $domain_realm
dns-nameservers $(hostname -I | cut -d ' ' -f 1)
dns-nameservers 8.8.8.8
EOL

systemctl restart networking.service

mv /etc/sysctl.conf /etc/sysctl.conf.bkp
cat > /etc/sysctl.conf << EOL
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.eth0.disable_ipv6 = 1
EOL

mv /etc/hosts /etc/hosts.bkp
cat > /etc/hosts << EOL
127.0.0.1 localhost
$(hostname -I | cut -d ' ' -f 1) $hostname $HOSTNAME localhost
EOL

systemctl stop smbd nmbd winbind;
systemctl disable smbd nmbd winbind;
systemctl stop systemd-networkd;
systemctl disable systemd-networkd;

mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
samba-tool domain provision --use-rfc2307 --server-role=dc --dns-backend=SAMBA_INTERNAL --realm=$domain_realm --domain=$domain_name --adminpass=$pass --option="interfaces=lo $nic"

systemctl unmask samba-ad-dc
systemctl enable samba-ad-dc
systemctl stop winbind;
systemctl stop samba-ad-dc;
systemctl start samba-ad-dc

#systemctl restart samba-ad-dc
#systemctl status samba-ad-dc

samba-tool spn add ldap/$domain_realm Administrator
samba-tool spn add cifs/$domain_realm Administrator

sudo systemctl stop ntpsec

sudo sed -i "s/pool /#pool/g" /etc/ntpsec/ntp.conf

cat >> /etc/ntpsec/ntp.conf << EOL

server a.ntp.br iburst
server b.ntp.br iburst
server c.ntp.br iburst

# Relogio Local
server 127.127.1.0
fudge 127.127.1.0 stratum 10
# Configurações adicionais para o Samba 4
ntpsigndsocket /var/lib/samba/ntp_signd/
restrict default mssntp
disable monitor
EOL

#sudo sed -i '23p' /etc/ntpsec/ntp.conf

#sed -i '23s/^/server a.ntp.br iburst\n/g' /etc/ntpsec/ntp.conf
#sed -i '23s/^/server b.ntp.br iburst\n/g' /etc/ntpsec/ntp.conf
#sed -i '23s/^/server c.ntp.br iburst\n/g' /etc/ntpsec/ntp.conf

sudo chown -v root:ntpsec /var/lib/samba/ntp_signd/
sudo chmod -v 750 /var/lib/samba/ntp_signd/

cat >> /etc/cron.d/server.conf << EOF
bindaddress $(hostname -I | cut -d ' ' -f 1)
allow $(hostname -I | cut -d ' ' -f 1 | cut -d '.' -f 1-3).1/24
ntpsigndsocket  /var/lib/samba/ntp_signd
EOF

cat >> /etc/cron.d/cmd.conf << EOF
bindcmdaddress /var/run/crond.pid
cmdport 0
EOF

sudo systemctl enable --now cron
sudo ntpdate pool.ntp.br
sudo service ntpsec start

samba-tool domain exportkeytab /etc/krb5.keytab

#ls -l /etc/krb5.keytab
#chmod 755 /etc/krb5.keytab
#ls -l /etc/krb5.keytab

mv /etc/krb5.conf /etc/krb5.conf.initial
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
cp /etc/krb5.conf /etc/krb5.conf.bkp.samba

sudo sed -i 's/\[libdefaults\]/\[libdefaults\]\
rdns = false\
default_tgs_enctypes = rc4-hmac des3-hmac-sha1\
default_tkt_enctypes = rc4-hmac des3-hmac-sha1\
permitted_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1\
#ticket_lifetime = 24h\
ticket_lifetime = 86400\
forwardable = true\
udp_preference_limit = 1000000\
#renew_lifetime = 7d\
renew_lifetime = 604800\
default_ccache_name = \/etc\/samba\/krb5cc_%\{uid\}\
udp_preference_limit = 1\
kdc_timeout = 3000\
/g' /etc/krb5.conf

sudo sed -i 's/\dns_lookup_kdc = true/dns_lookup_kdc = false/g' /etc/krb5.conf

sudo sed -i "s/$domain = {/$domain = {\n\
kdc = $hostname\n\
admin_server = $hostname\
/g" /etc/krb5.conf

sudo sed -i "s/$HOSTNAME = $domain/\
.$domain_realm = $domain\n\
$domain_realm = $domain\n\
/g" /etc/krb5.conf

cat >> /etc/krb5.conf << EOL
[logging]
kdc = FILE:/var/log/krb5kdc.log
admin_server = FILE:/var/log/kadmin.log
default = FILE:/var/log/krb5lib.log
EOL

sudo sed -i "s/passwd:         files/passwd:         compat files systemd/g" /etc/nsswitch.conf
sudo sed -i "s/group:          files/group:          compat files systemd/g" /etc/nsswitch.conf

cat >> /etc/samba/user.map << EOL
!root = $domain_name\Administrator $domain_name\administrator Administrator administrator
EOL

cp /etc/samba/smb.conf /etc/samba/smb.conf.bkp.provision

sudo sed -i "s/\[global\]/\[global\]\n\
dns forwarder = 8.8.8.8\n\
/g" /etc/samba/smb.conf

cp /etc/samba/smb.conf /etc/samba/smb.conf.initial
sudo sed -i "s/\[sysvol\]/\
password server = $(hostname -I | cut -d ' ' -f 1)\n\
#winbind enum users = yes\n\
#winbind enum groups = yes\n\
#winbind nss info = rfc2307\n\
\n\
template homedir = \/home\/%U\n\
template shell = \/bin\/bash\n\
create mask = 0664\n\
directory mask = 0775\n\
\n\
## Configuração RSAT ##\n\
rpc_server:tcpip = no\n\
rpc_daemon:spoolssd = embedded\n\
rpc_server:spoolss = embedded\n\
rpc_server:winreg = embedded\n\
rpc_server:ntsvcs = embedded\n\
rpc_server:eventlog = embedded\n\
rpc_server:srvsvc = embedded\n\
rpc_server:svcctl = embedded\n\
rpc_server:default = external\n\
\n\
client min protocol = SMB2\n\
client max protocol = SMB3\n\
server min protocol = SMB2\n\
server max protocol = SMB3\n\
## Configuração RSAT ##\n\
\n\
logging = file\n\
max log size = 1000\n\
log file = \/var\/log\/samba\/log.%m\n\
log level = 1\n\
\n\
passdb backend = tdbsam\n\
kerberos method = secrets and keytab\n\
ldap server require strong auth = no\n\
map to guest = Bad User\n\
\n\
vfs objects = dfs_samba4 acl_xattr recycle\n\
#vfs objects = acl_xattr\n\
#vfs objects = dfs_samba4 acl_xattr audit\n\
\n\
map acl inherit = yes\n\
acl allow execute always = yes\n\
store dos attributes = yes\n\
username map = \/etc\/samba\/user.map\n\
#enable privileges = yes\n\
preferred master = yes\n\
case sensitive = No\n\
\n\
wins support = yes\n\
hosts allow = ALL\n\
name resolve order = lmhosts host wins bcast\n\
\n\
## Desabilita compartilhamento de impressoras\n\
printcap name = \/dev\/null\n\
load printers = no\n\
disable spoolss = yes\n\
printing = bsd\n\
\n\
#security = user \n\
idmap config $domain_name : unix_nss_info = no\n\
idmap config $domain_name : backend = ad  \n\
#idmap config $domain_name : range = 10000-59999 \n\
idmap config * : backend = tdb \n\
idmap config * : range = 3000-7999 \n\
\n\[sysvol\]/" /etc/samba/smb.conf

sudo sed -i "s/interfaces = lo $nic/interfaces = lo $nic $ip1.$ip2.$ip3.$ip4\/24/g" /etc/samba/smb.conf

#sudo sed -i 's/winbindd/winbind/g' /etc/samba/smb.conf

sudo smbcontrol all reload-config

sudo systemctl restart samba-ad-dc
sudo pam-auth-update --enable mkhomedir
sudo systemctl unmask samba-ad-dc
sudo systemctl enable samba-ad-dc
sudo systemctl start samba-ad-dc

apt -y install resolvconf
mv $(dpkg -S resolv.conf | grep head | cut -d ' ' -f 2) $(dpkg -S resolv.conf | grep head | cut -d ' ' -f 2).bkp
cat > $(dpkg -S resolv.conf | grep head | cut -d ' ' -f 2) << EOF
nameserver $(hostname -I | cut -d ' ' -f 1)
nameserver $gateway
nameserver 8.8.8.8
domain $domain_name
search $domain.
EOF

systemctl enable resolvconf.service
systemctl start resolvconf.service
systemctl restart networking.service

kinit -kt /etc/krb5.keytab Administrator@$domain
klist

echo
echo
echo "Iniciando Verificação Geral do Sistema..."
echo
echo
sleep 2
echo "-------------------------------------------------"
echo " Cadastrando ZONA REVERSA..."
echo
echo $pass | samba-tool dns zonecreate $hostname $ip3.$ip2.$ip1.in-addr.arpa -U administrator
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo " Cadastrando PTR..."
echo
echo $pass | samba-tool dns add $hostname $ip3.$ip2.$ip1.in-addr.arpa $ip4 PTR $hostname -U administrator
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo "Informações do SID..."
echo
ldbsearch -H /var/lib/samba/private/sam.ldb DC=$domain_name | grep objectSid
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo " Teste do SMBClient..."
echo
smbclient -L localhost -N
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo "Teste SMBCliente com Login"
echo
echo "$pass" | smbclient //localhost/netlogon -U Administrator -c 'ls'
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo "Teste de Descoberta Kerberos..."
echo
host -t SRV _kerberos._udp.$domain_realm.
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo "Teste de Descoberta LDAP..."
echo
host -t SRV _ldap._tcp.$domain_realm.
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo " Teste DNS Reverso Dominio: $domain_realm..."
echo
nslookup $domain_realm
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo " Teste DNS Reverso IP: $(hostname -I | cut -d ' ' -f 1) ..."
echo
nslookup $(hostname -I | cut -d ' ' -f 1)
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo " Teste DNS Reverso Host $(hostname -I | cut -d ' ' -f 1)"
echo
host $(hostname -I | cut -d ' ' -f 1)
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo " Nivel do Dominio ao Windows "
echo
sudo samba-tool domain level show
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo " Sincronização ntpsec ..."
echo
sudo ntpq -p
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo " Teste do GETENT                     "
echo
getent passwd administrator
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo " Conceder privilégios para configurar ACLs pelo Windows "
echo
echo $pass | net rpc rights grant "$domain_name\Administrator" SeDiskOperatorPrivilege -U "$domain_name\Administrator"
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo " Definindo senha "nunca expira" para administrator"
echo
samba-tool user setexpiry administrator --noexpiry
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------------------"
echo "Informações SPN ..."
echo
samba-tool spn list Administrator
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------"
echo "Verificando erros ..."
echo
samba-tool dbcheck --cross-ncs
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "-------------------------------------"
echo "Verificando conexão com a internet ..."
echo
ping -c4 google.com
echo
echo "OK!"
echo "-------------------------------------------------"
echo
sleep 2
echo "Sistema verificado com Sucesso "
echo
sleep 2
echo "-------------------------------------------------"
echo " O Dominio do sistema é $domain"
echo " O usuário é administrator, e a senha é $pass"
echo "-------------------------------------------------"
exit 0
}
