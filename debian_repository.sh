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

echo "-------------------------------------------------"
echo "[ Repositório - $CODENAME ]: Verificando ..."
sleep 2
if [ -e $PATH_SOURCE ]
then
echo "[ Repositório - $CODENAME ]: - OK!"
else
echo "[ Repositório - $CODENAME ]: Configurando ..."
sleep 2
mv /etc/apt/sources.list /etc/apt/sources.list.bkp 2>&1 | grep "mv"
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

echo "-------------------------------------------------"
echo "[ NOVOS Repositórios ]: Verificando ..."
sleep 2
if [ ! -e ~/repo ]
then
echo "[ NOVOS Repositórios ]: Não há"
else
sh ~/repo
echo "[ NOVOS Repositórios ]: OK!"
fi

echo "-------------------------------------------------"
echo "[ Prioridade IPv4 ]: Verificando ..."
sleep 2
if grep ^'precedence ::ffff:0:0/96  100'  /etc/gai.conf > /dev/null
then
echo "[ Prioridade IPv4 ]: OK!"
else
echo "[ Prioridade IPv4 ]: Configurando ... "
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
sleep 2
echo "[ Prioridade IPv4 ]: OK!"
fi

echo "-------------------------------------------------"
echo "[ Fix LDCONFIG ]: Verificando ..."
sleep 2
if grep ^'export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin' ~/.bashrc > /dev/null
then
echo "[ Fix LDCONFIG ]: OK!"
else
echo "[ Fix LDCONFIG ]: Configurando ... "
echo 'export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin' >> ~/.bashrc
source /etc/profile
echo "[ Fix LDCONFIG ]: OK!"
fi

echo "-------------------------------------------------"
echo "[ Sistema ]: Atualizando ..."
sleep 2
apt-get update -qq 2>&1 | grep "E:"
apt-get upgrade -qqy 2>&1 | grep "E:"
systemctl daemon-reload 2>&1 | grep "E:"
apt-get --fix-broken -qq install | grep "E:"
sleep 2
echo "[ Sistema ]: OK!"
echo "-------------------------------------------------"
