#!/bin/bash
CODENAME=stable

TYPES='deb deb-src'
URIS='http://deb.debian.org/debian'
URIS_SEC='http://deb.debian.org/debian-security'
SUITES="$CODENAME $CODENAME-updates $CODENAME-backports"
SUITES_SEC="$CODENAME-security"
COMPONENTES='main contrib non-free non-free-firmware'
SIGNED='/usr/share/keyrings/debian-archive-keyring.gpg'
PATH_SOURCE="/etc/apt/sources.list.d/$CODENAME.sources"


if [ -e PATH_SOURCE ];
then
  echo
  echo "Lista de repositórios atualizado"
  echo
else
  echo
  echo "Atualizando lista de repositórios..."
  echo
  mv /etc/apt/sources.list /etc/apt/sources.list.bkp

  cat <<EOF>> $PATH_SOURCE 
  ## DEBIAN STABLE RESPOSITORY 
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
  echo "OK!"
fi
echo "Atualizando sistema..."
echo
apt update -qq 2>&1 | grep "E:"
apt upgrade -qqy 2>&1 | grep "E:"
systemctl daemon-reload 2>&1 | grep "E:"
apt --fix-broken -qq install 2>&1 | grep "E:"
echo
echo "Sistema Atualizado!"
