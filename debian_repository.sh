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
echo "[ Sistema ]: Definindo IPv4 como prioridade"
echo "-------------------------------------------------"
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
sleep 2
echo "OK!"

echo
echo "[ Sistema ]: Verificando ... "
sleep 2

echo
if [ -e $PATH_SOURCE ];
  then
    echo "[ Repositório ]: OK!"
    sleep 2
  else
    echo "[ Repositório ]: Configurando ..."
    sleep 2
    mv /etc/apt/sources.list /etc/apt/sources.list.bkp 2>&1
    sleep 2
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
    echo "[ Repositório ]: OK!"
    sleep 2
fi

PATH_REPO=$($PWD)
if [ -e $PATH_REPO/repo ];
  echo "[ Repositório ]: Verificando NOVOS repositórios ..."
  sleep 2
  then
  echo "[ Repositório ]: Configurando NOVOS repositórios ..."
#sh $pwd/repo
cat $PATH_REPO/repo
  echo "[ Repositório ]: NOVOS repositórios OK!"
  else
  echo "[ Repositório ]: NÃO há NOVOS repositórios"
fi

echo
echo "[ Sistema ]: Atualizando ..."
apt-get update -qq 2>&1 | grep "E:"
apt-get upgrade -qqy 2>&1 | grep "E:"
systemctl daemon-reload 2>&1 | grep "E:"
apt-get --fix-broken -qq install | grep "E:"
sleep 2
echo "[ Sistema ]: OK!"
echo
sleep 2
