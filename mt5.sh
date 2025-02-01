#!/bin/sh
# Verifica se o ID do usuário atual é 0 (root)

if [ $EUID -ne 0 ];
then
echo "Você precisa ser root para executar este comando. Por favor, mude para o root"
sleep 3
echo "Saindo..."
sleep 3
exit
else
echo "Você está logado como root."
fi

echo "[ Sistema ]: Verificando..."
curl -fsSL https://raw.githubusercontent.com/davigalucio/linux/main/debian_repository.sh | sh 
echo "[ Sistema ]: OK!"
echo "--------------------------------------------------------------------"
echo "[ Essentials ]: Verificando..."
curl -fsSL https://raw.githubusercontent.com/davigalucio/linux/main/essentials.sh | sh
echo "[ Essentials ]: OK!"
echo "--------------------------------------------------------------------"

# -------  REPOSITORIO WINEHQ ------- INICIO
DEBIAN_VERSION_CODENAME=$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2)
PATH_SOURCE=/etc/apt/sources.list.d/winehq-$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2).sources

if [ -e $PATH_SOURCE ]
then
echo "[ Repositório - WINEHQ ]: - OK!"
else
echo "[ Repositório - WINEHQ ]: - Configurando..."
mkdir -pm755 /etc/apt/keyrings
wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key > /dev/null
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/stable/winehq-$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2).sources > /dev/null
dpkg --add-architecture i386
apt-get update -qq  > /dev/null
apt-get upgrade -qqy  > /dev/null
systemctl daemon-reload  > /dev/null
apt-get --fix-broken -qq install  > /dev/null
echo "[ Repositório - WINEHQ ]: - OK!"
fi

# ------- REPOSITORIO WINEHQ ------- FIM

# ------- INSTALAÇÃO WINEHQ ------- INICIO
PACKAGES="winehq-stable winetricks mono-complete fonts-wine wine-binfmt winbind ttf-mscorefonts-installer binfmt-support xorg xvfb gtk2-engines-pixbuf imagemagick xauth vulkan-tools python3 libwine libwine-dev libkwineffects14 libvulkan1 libvkd3d1 libvulkan-dev libasound2-dev libinput-dev libssl-dev libxcomposite-dev libx11-dev libxrandr-dev libpng-dev libgtk-3-dev libsqlite3-dev libz-mingw-w64 libc6-i386 zlib1g libxft2 libcairo2 libpcl1 libpcl1-dev libmpg123-dev libeio1 libeinfo1 libxext-dev libfreetype6-dev libxfixes-dev libpcap-dev libdbus-1-dev libopenal-dev libgl1-mesa-dev libv4l-dev libsdl2-dev libgphoto2-dev libodbc1 libgnutls28-dev zlib1g-dev libglm-dev libdrm-dev mesa-utils"
curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh > /dev/null
INSTALLER="install.sh"
echo "[ INSTALAÇÃO WINEHQ  ]: Inicio"
if grep PACKAGE_NAME $INSTALLER > /dev/null
  then
    sed -i "s|PACKAGE_NAME|$PACKAGES|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ INSTALAÇÃO WINEHQ  ]: Fim."
sleep 2
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
# ------- INSTALAÇÃO WINEHQ ------- FIM

# ------- INSTALAÇÃO WINETRICKS ------- INICIO

PATH_SOURCE="/opt/wine-stable/win64apps"
if [ -e $PATH_SOURCE ]
then
echo "[ $PATH_SOURCE  ]: OK!"
else
echo "[ $PATH_SOURCE  ]: Criando..."
mkdir $PATH_SOURCE
sleep 2
echo "[ $PATH_SOURCE  ]: OK!"
fi

winedir=/opt/wine-stable/win64apps
chown -R $USER:$USER $winedir

PATH_SOURCE="$PWD/.cache"
if [ -e $PATH_SOURCE ]
then
echo "[ $PATH_SOURCE  ]: OK!"
else
echo "[ $PATH_SOURCE  ]: Criando..."
mkdir $PATH_SOURCE
sleep 2
echo "[ $PATH_SOURCE  ]: OK!"
fi

PATH_SOURCE="$PWD/.cache/wine"
if [ -e $PATH_SOURCE ]
then
echo "[ $PATH_SOURCE  ]: OK!"
else
echo "[ $PATH_SOURCE  ]: Criando..."
mkdir $PATH_SOURCE
sleep 2
echo "[ $PATH_SOURCE  ]: OK!"
fi
chown -R $USER:$USER $PWD

PATH_SOURCE=$PWD/.cache/wine/wine-mono-9.4.0-x86.msi
if [ -e $PATH_SOURCE ]
then
echo "[ $PATH_SOURCE  ]: OK!"
else
echo "[ $PATH_SOURCE  ]: Downloading..."
wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-mono/9.4.0/wine-mono-9.4.0-x86.msi > /dev/null
sudo -u $USER WINEPREFIX="$winedir/.wine" wine msiexec /i $PWD/.cache/wine/wine-mono-9.4.0-x86.msi > /dev/null
sleep 2
echo "[ $PATH_SOURCE  ]: OK!"
fi

PATH_SOURCE=$PWD/.cache/wine/wine-gecko-2.47.4-x86_64.msi
if [ -e $PATH_SOURCE ]
then
echo "[ $PATH_SOURCE  ]: OK!"
else
echo "[ $PATH_SOURCE  ]: Downloading..."
wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi > /dev/null
sudo -u $USER WINEPREFIX="$winedir/.wine" wine msiexec -i $PWD/.cache/wine/wine-gecko-2.47.4-x86_64.msi > /dev/null
sleep 2
echo "[ $PATH_SOURCE  ]: OK!"
fi

PACKAGES="forcemono mimeassoc=on vkd3d dxvk2010 dxvk vcrun2010 vcrun2015 dotnet48 msxml3 msxml6 mfc140 directplay d3dx9 d3dx9_43 d3dx11_43 d3dcompiler_43 d3dcompiler_47 dsound windowscodecs dinput8 xinput xact devenum richtx32 corefonts"
WINEPREFIX_PATH='WINEPREFIX="/opt/wine-stable/win64apps/.wine"'

curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install-winetricks.sh > /dev/null
INSTALLER="install-winetricks.sh"

sed -i "s|WINEPREFIX_PATH|$WINEPREFIX_PATH|g" $INSTALLER

echo
echo "[ Instalação Winetricks ]: Inicio"
if grep PACKAGE_NAME $INSTALLER > /dev/null
  then
    sed -i "s|PACKAGE_NAME|$PACKAGES|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ Instalação Winetricks ]: Fim."
echo

# ------- INSTALAÇÃO WINETRICKS ------- FIM

sudo -u $USER WINEPREFIX="$winedir/.wine" WINEARCH=win64 wine wineboot -u -f -r > /dev/null
sudo -u $USER WINEPREFIX="$winedir/.wine" wineserver -k > /dev/null
sudo -u $USER WINEPREFIX="$winedir/.wine" wine winecfg -v win10 > /dev/null

PATH_SOURCE=$winedir/.cache/wine/mt5setup.exe
if [ -e $PATH_SOURCE ]
then
echo "[ $PATH_SOURCE  ]: OK!"
else
echo "[ $PATH_SOURCE  ]: Downloading..."
wget -P $winedir/.cache/wine https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe > /dev/null
sudo -u $USER WINEPREFIX="$winedir/.wine" wine $winedir/.cache/wine/mt5setup.exe /auto > /dev/null
sleep 2
echo "[ $PATH_SOURCE  ]: OK!"
fi

echo
sleep 3
echo
echo "------------------------------------------------------------------------------"
echo "[ WINEPREFIX ]: $(echo $WINEPREFIX_PATH)"
echo "[ Metatrader 5 ]: $(find / | grep terminal64.exe)"
echo "[ Metatrader 5 ]: Concluído"
