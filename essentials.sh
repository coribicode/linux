PACKAGES="build-essential firmware-linux lsb-release apt-transport-https module-assistant ca-certificates software-properties-common aptitude sudo wget git curl perl tar unzip lzip xorg xvfb xauth pulseaudio alsa-utils alsa-tools libasound2 libasound2-dev udns-utils net-tools rfkill neofetch screenfetch cmake g++ gcc make automake autoconf flex bison bc gdb gnupg gnupg1 gnupg2 gnutls-bin libjwt-gnutls-dev"
echo
curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh > /dev/null 2>&1
INSTALLER="install.sh"

echo "[ Essentials ]: Inicio"
if grep PACKAGE_NAME $INSTALLER > /dev/null 2>&1
  then
    sed -i "s|PACKAGE_NAME|$PACKAGES|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ Essentials ]: Fim."
sleep 2
