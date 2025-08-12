# -------  REPOSITORIO WINEHQ ------- INICIO
DEBIAN_VERSION_CODENAME=$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2)
PATH_SOURCE=/etc/apt/sources.list.d/winehq-$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2).sources

if [ -e $PATH_SOURCE ]
then
echo "[ Repositório - WINEHQ ]: - OK!"
else
echo "[ Repositório - WINEHQ ]: - Configurando..."
mkdir -pm755 /etc/apt/keyrings > /dev/null 2>&1
wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key > /dev/null 2>&1
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/stable/winehq-$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2).sources > /dev/null 2>&1
dpkg --add-architecture i386
apt-get update -qq  > /dev/null 2>&1
apt-get upgrade -qqy  > /dev/null 2>&1
systemctl daemon-reload  > /dev/null 2>&1
apt-get --fix-broken -qq install  > /dev/null 2>&1
echo "[ Repositório - WINEHQ ]: - OK!"
fi

# ------- REPOSITORIO WINEHQ ------- FIM

# ------- INSTALAÇÃO WINEHQ ------- INICIO
PACKAGES="wine winetricks mono-complete fonts-wine wine-binfmt winbind ttf-mscorefonts-installer binfmt-support xorg xvfb gtk2-engines-pixbuf imagemagick xauth vulkan-tools python3 libwine libwine-dev libkwin6 libvulkan1 libvkd3d1 libvulkan-dev libasound2-dev libinput-dev libssl-dev libxcomposite-dev libx11-dev libxrandr-dev libpng-dev libgtk-3-dev libsqlite3-dev libz-mingw-w64 libc6-i386 zlib1g libxft2 libcairo2 libpcl-dev libmpg123-dev libeio1 libeinfo1 libxext-dev libfreetype-dev libxfixes-dev libpcap-dev libdbus-1-dev libopenal-dev libgl1-mesa-dev libv4l-dev libsdl2-dev libgphoto2-dev libodbc1 libgnutls28-dev zlib1g-dev libglm-dev libdrm-dev mesa-utils"
curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh > /dev/null 2>&1
INSTALLER="install.sh"
echo "[ INSTALAÇÃO WINEHQ  ]: Inicio"
if grep PACKAGE_NAME $INSTALLER > /dev/null 2>&1
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
