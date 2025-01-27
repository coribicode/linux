#!/bin/bash
echo "[ Essentials ]: Verificando..."
curl -fsSL https://raw.githubusercontent.com/davigalucio/linux/main/essentials.sh | sh
echo "[ Essentials ]: OK!"
echo "--------------------------------------------------------------------"
echo "[ Sistema ]: Verificando..."
curl -fsSL https://raw.githubusercontent.com/davigalucio/linux/main/debian_repository.sh | sh
echo "[ Sistema ]: OK!"
echo "--------------------------------------------------------------------"

PACKAGES="lxde-core xrdp chromium network-manager-gnome"

echo
echo "Instalação do Server minimal LXDE-CORE"
sleep 2
echo "Pacostes a serem instalados: $PACKAGES"
sleep 3
echo "Instalando..."
sleep 3
echo

curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh 2>/dev/null | grep "E:"
INSTALLER="install.sh"

echo
echo "[ Instalação ]: Inicio"
if grep PACKAGE_NAME $INSTALLER > /dev/null
  then
    sed -i "s|PACKAGE_NAME|$PACKAGES|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ Instalação ]: Fim."
echo
sleep 2

echo
if grep ^'managed=false' /etc/NetworkManager/NetworkManager.conf > /dev/null
then
echo "[ Network Manager ]: Configurando..."
cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.bkp
sed -i 's|managed=false|managed=true|g' /etc/NetworkManager/NetworkManager.conf
sed -i 's|plugins=ifupdown,keyfile|plugins=keyfile|g' /etc/NetworkManager/NetworkManager.conf
sleep 2
echo "[ Network Manager ]: OK!"
else
echo "[ Network Manager ]: OK!"
fi

# Identifica as interfaces de rede que estão UP e configura em /etc/network/interfaces.d/*
count=0
for iface in $(ip link show | awk '/BROADCAST/ {print $2}' | sed 's/:$//'); do
# Incrementa o contador
count=$((count + 1))
# Cria a variável dinamicamente com o nome ifaceX e atribui o nome da interface
eval "INTERFACE$count='$iface'"
ip link set $iface up    
# Configurando a interface [ dhcp ]
if [ -e /etc/network/interfaces.d/$iface ] > /dev/null
then
echo "----------------------------"
echo "[ $iface ]: OK"
else
echo "----------------------------"
echo "[ $iface ]: Configurando ..."
sleep 2
cat >> /etc/network/interfaces.d/$iface << EOL
#Configuração $iface
auto $iface
allow-hotplug $iface
iface $iface inet dhcp
EOL
echo "[ $iface ]: OK."
fi
done

if [ -e /etc/network/interfaces.d/lo ] > /dev/null
then
echo "----------------------------"
echo "[ lo ]: OK"
else
echo "----------------------------"
echo "[ lo ]: Configurando ..."
sleep 2
cat >> /etc/network/interfaces.d/lo << EOL
#Configuração lo
auto lo
iface lo inet loopback
EOL
echo "[ lo ]: OK."
fi
echo "----------------------------"

cp /etc/network/interfaces /etc/network/interfaces.bkp
sed -i 's/^/# /' /etc/network/interfaces
sed -i 's/# source/source/g' /etc/network/interfaces

sudo rfkill unblock all
sudo rfkill list all

systemctl daemon-reload
systemctl restart networking
systemctl restart NetworkManager

# https://askubuntu.com/questions/98702/how-to-unblock-something-listed-in-rfkill
# https://superuser.com/questions/819547/how-do-i-stop-rfkill-module-from-hardblocking-my-wifi-without-rfkill-command

#package='curl'
#echo "--------------------------------------------------------------------"
#if [ -n "$(dpkg --get-selections | grep ^$package | grep -w install)" ] ;
#then
#echo "Pacote [ $package ]: OK!"
#echo "--------------------------------------------------------------------"
#else
#echo "Pacote [ $package ]: Instalando...!"
#apt-get install -y $package > /dev/null
#echo "Pacote [ $package ]: OK!"
#fi
