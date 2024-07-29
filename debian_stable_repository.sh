#!/bin/bash
CODENAME='stable'
TYPES='deb deb-src'
URIS='http://deb.debian.org/debian'
URIS_SEC='http://deb.debian.org/debian-security'
SUITES="$CODENAME $CODENAME-updates $CODENAME-backports"
SUITES_SEC="$CODENAME-security"
COMPONENTES='main contrib non-free non-free-firmware'
SIGNED='/usr/share/keyrings/debian-archive-keyring.gpg'
PATH_SOURCE="/etc/apt/sources.list.d/$CODENAME.sources"


if [ -e $PATH_SOURCE ];
  then
    echo
    echo "Repositório [$PATH_SOURCE]: OK!"
    sleep 2
  else
    echo
    echo "Repositório []: Atualizando..."
    sleep 2
    mv /etc/apt/sources.list /etc/apt/sources.list.bkp
    sleep 2
    touch $PATH_SOURCE
    echo "## DEBIAN STABLE RESPOSITORY" >> $PATH_SOURCE
    echo "Types: $TYPES" >> $PATH_SOURCE
    echo "URIs: $URIS" >> $PATH_SOURCE
    echo "Suites: $SUITES" >> $PATH_SOURCE
    echo "Components: $COMPONENTES" >> $PATH_SOURCE
    echo "Signed-By: $SIGNED" >> $PATH_SOURCE
    echo "" >> $PATH_SOURCE
    echo "Types: $TYPES" >> $PATH_SOURCE
    echo "URIs: $URIS_SEC" >> $PATH_SOURCE
    echo "Suites: $SUITES_SEC" >> $PATH_SOURCE
    echo "Components: $COMPONENTES" >> $PATH_SOURCE
    echo "Signed-By: $SIGNED" >> $PATH_SOURCE
    sleep 2
    echo "Repositório [$PATH_SOURCE]: OK!"
    sleep 2
fi

echo
echo "SISTEMA: Atualizando..."
apt update -qq 2>&1 | grep "E:"
apt upgrade -qqy 2>&1 | grep "E:"
systemctl daemon-reload 2>&1 | grep "E:"
apt --fix-broken -qq install 2>&1 | grep "E:"
sleep 2
echo "SISTEMA: OK!"
echo
sleep 2
