#!/bin/bash
apt-get install -y curl > /dev/null
curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh 2>/dev/null | grep "E:"

INSTALLER="install.sh"
PACKAGES_DEPENDECES="lxde-core xrdp chromium network-manager-gnome"

echo
echo "[ Instalação de Pacotes ]"
if grep PACKAGE_NAME $INSTALLER > /dev/null
  then
    sed -i "s|PACKAGE_NAME|$PACKAGES_DEPENDECES|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ Instalação de Pacotes ]: OK!"
sleep 2

echo
if grep ^'managed=false' /etc/NetworkManager/NetworkManager.conf > /dev/null
then
echo "[ Network Manager ]: Configurando..."
sed -i 's|managed=false|managed=true|g' /etc/NetworkManager/NetworkManager.conf
service NetworkManager restart
sleep 2
echo "[ Network Manager ]: OK!"
else
echo "[ Network Manager ]: OK!"
fi

count=0
# Identifica as interfaces de rede que estão UP e as configura como variáveis INTERFACE0, INTERFACE1, etc.
for iface in $(ip link show | awk '/BROADCAST/ {print $2}' | sed 's/:$//'); do
# Incrementa o contador
count=$((count + 1))

# Cria a variável dinamicamente com o nome INTERFACEX e atribui o nome da interface
eval "INTERFACE$count='$iface'"
ip link set $iface up
    
if grep $iface /etc/network/interfaces > /dev/null
then
echo "----------------------------"
echo "[ $iface ]: OK"
else
echo "----------------------------"
echo "[ $iface ]: Configurando ..."
sleep 2
cat >> /etc/network/interfaces << EOL

#Configuração $iface
auto $iface
allow-hotplug $iface
iface $iface inet dhcp
EOL

echo "[ $iface ]: OK."
fi
done
echo "----------------------------"

# https://askubuntu.com/questions/98702/how-to-unblock-something-listed-in-rfkill
# https://superuser.com/questions/819547/how-do-i-stop-rfkill-module-from-hardblocking-my-wifi-without-rfkill-command
sudo rfkill unblock all
sudo rfkill list all

systemctl daemon-reload
systemctl restart networking

