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
if [ -e $PATH_SOURCE ];
  then
  echo "[ Repositório ]: $CODENAME - OK!"
  echo "-------------------------------------------------"
sleep 2
  else
  echo "[ Repositório ]: $CODENAME - Configurando ..."
  mv /etc/apt/sources.list /etc/apt/sources.list.bkp 2>&1
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
sleep 2
  echo "[ Repositório ]: $CODENAME - OK!"
  echo "-------------------------------------------------"
sleep 2
fi

if [ -e ~/repo ];
  then
  echo "[ NOVOS Repositórios ]: Verificando ..."
sh ~/repo
sleep 2
  echo "[ NOVOS Repositórios ]: OK!"
  echo "-------------------------------------------------"
  else
  echo "[ NOVOS Repositórios ]: Não há"
  echo "-------------------------------------------------"
sleep 2
fi

if grep ^'precedence ::ffff:0:0/96  100'  /etc/gai.conf > /dev/null
  then
  echo "[ Prioridade IPv4 ]: OK!"
  echo "-------------------------------------------------"
sleep 2
  else
  echo "[ Prioridade IPv4 ]: Configurando ... "
  echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
sleep 2
  echo "[ Prioridade IPv4 ]: OK!"
  echo "-------------------------------------------------"
sleep 2
fi

echo "[ Sistema ]: Atualizando ..."
apt-get update -qq 2>&1 | grep "E:"
apt-get upgrade -qqy 2>&1 | grep "E:"
systemctl daemon-reload 2>&1 | grep "E:"
apt-get --fix-broken -qq install | grep "E:"
sleep 2
echo "[ Sistema ]: OK!"
echo "-------------------------------------------------"
sleep 2
