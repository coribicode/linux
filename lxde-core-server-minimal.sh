debian_repository=https://raw.githubusercontent.com/davigalucio/linux/main/debian_repository.sh
curl -fsSL $debian_repository | sh

essentials=https://raw.githubusercontent.com/davigalucio/linux/main/essentials.sh
curl -fsSL $essentials | sh

curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh 2>/dev/null | grep "E:"

INSTALLER="install.sh"
PACKAGES_DEPENDECES="lxde-core xrdp chromium network-manager network-manager-gnome"

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
sleep 2
echo "[ Network Manager ]: OK!"
else
echo "[ Network Manager ]: OK!"
fi
