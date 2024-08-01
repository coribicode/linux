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

if [ -e repo ];
  echo "[ Repositório ]: Verificando NOVOS repositórios ..."
  sleep 2
  then
  echo "[ Repositório ]: Configurando NOVOS repositórios ..."
sh repo
  echo "[ Repositório ]: NOVOS repositórios OK!"
fi

echo
echo "[ Sistema ]: Atualizando ..."
apt update -qq 2>&1 | grep "E:"
apt upgrade -qqy 2>&1 | grep "E:"
systemctl daemon-reload 2>&1 | grep "E:"
apt --fix-broken -qq install | grep "E:"
sleep 2
echo "[ Sistema ]: OK!"
echo
sleep 2
