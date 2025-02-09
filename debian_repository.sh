#!/bin/bash
CODENAME='stable'
TYPES='deb deb-src'
URIS='http://deb.debian.org/debian'
URIS_SEC='http://deb.debian.org/debian-security'
SUITES="$CODENAME $CODENAME-updates $CODENAME-backports"
SUITES_SEC="$CODENAME-security"
COMPONENTES='main contrib non-free non-free-firmware'
SIGNED="/usr/share/keyrings/debian-archive-keyring.gpg"
PATH_SOURCE="/etc/apt/sources.list.d/$CODENAME.sources"

echo
echo "### REPOSITORIO DEBIAN STABLE ###"
echo "-------------------------------------------------"
echo "[ Prioridade IPv4 ]: Verificando ..."
sleep 2
if grep ^'precedence ::ffff:0:0/96  100' /etc/gai.conf > /dev/null 2>&1
then
echo "[ Prioridade IPv4 ]: OK!"
else
echo "[ Prioridade IPv4 ]: Configurando ... "
sed -i 's|#precedence ::ffff:0:0/96  100|precedence ::ffff:0:0/96  100|g' /etc/gai.conf
sleep 2
echo "[ Prioridade IPv4 ]: OK!"
fi
sleep 2

echo "-------------------------------------------------"
echo "[ Fix LDCONFIG ]: Verificando ..."
sleep 2
if grep ^'export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin' ~/.bashrc > /dev/null 2>&1
then
echo "[ Fix LDCONFIG ]: OK!"
else
echo "[ Fix LDCONFIG ]: Configurando ... "
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
echo 'export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin' >> ~/.bashrc
echo 'export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin' >> /etc/profile
systemctl daemon-reload
#source ~/.bashrc 2>&1
#source /etc/profile 2>&1
ldconfig
echo "[ Fix LDCONFIG ]: OK!"
fi
sleep 2

echo "-------------------------------------------------"
echo "[ Repositório - $CODENAME ]: Verificando ..."
sleep 2
if [ -e $PATH_SOURCE ]
then
echo "[ Repositório - $CODENAME ]: - OK!"
else
echo "[ Repositório - $CODENAME ]: Configurando ..."
sleep 2
mv /etc/apt/sources.list /etc/apt/sources.list.bkp > /dev/null 2>&1
cat > $PATH_SOURCE << EOF
## $CODENAME RESPOSITORY ##
Types: $TYPES
URIs: $URIS
Suites: $SUITES
Components: $COMPONENTES
Signed-By: $SIGNED

Types: $TYPES
URIs: $URIS_SEC
Suites: $SUITES_SEC
Components: $COMPONENTES
Signed-By: $SIGNED
EOF
echo "[ Repositório - $CODENAME ]: OK!"
fi
sleep 2

echo "-------------------------------------------------"
echo "[ Sistema ]: Atualizando ..."
sleep 2
apt-get update -qq > /dev/null 2>&1
apt-get upgrade -qqy > /dev/null 2>&1
systemctl daemon-reload > /dev/null 2>&1 
apt-get --fix-broken -qq install > /dev/null 2>&1
echo "[ Sistema ]: OK!"
sleep 2

#echo "-------------------------------------------------"
#echo "[ GRUB - Interface FIX ]: Verificando ..."
#sleep 2
#if grep "net.ifnames=0 biosdevname=0"  /etc/default/grub > /dev/null 2>&1
#then
#echo "[ GRUB - Interface FIX ]: OK!"
#else
#echo "[ GRUB - Interface FIX ]: Configurando ... "
#sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"|g' /etc/default/grub
#sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="net.ifnames=0"|g' /etc/default/grub
#export PATH=/sbin:$PATH
#update-initramfs -u > /dev/null 2>&1
#update-grub > /dev/null 2>&1
#sleep 2
#echo "[ GRUB - Interface FIX ]: OK!"
#fi
#sleep 2

#echo "-------------------------------------------------"
#echo "[ NOVOS Repositórios ]: Verificando ..."
#sleep 2
#if [ ! -e ~/repo ]
#then
#echo "[ NOVOS Repositórios ]: Não há"
#else
#sh ~/repo
#echo "[ NOVOS Repositórios ]: OK!"
#fi
#sleep 2

sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && swapoff -a && rm -f -r /swapfile
