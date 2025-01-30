#!/bin/sh
DEBIAN_VERSION_CODENAME=$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2)

mkdir -pm755 /etc/apt/keyrings
wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/stable/winehq-$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2).sources

dpkg --add-architecture i386
apt update && apt upgrade -y && systemctl daemon-reload

apt install -y --install-recommends \
winehq-stable \
winetricks \
mono-complete \
fonts-wine \
wine-binfmt \
wine64 \
wine64-tools

echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

apt install -y --install-recommends \
winbind \
ttf-mscorefonts-installer \
binfmt-support \
xorg \
xvfb \
gtk2-engines-pixbuf \
imagemagick xauth \
vulkan-tools \
python3

apt install -y --install-recommends \
libc6-i386 \
zlib1g \
libxft2 \
libcairo2 \
libvulkan1 \
libpcl1 \
libpcl1-dev \
libvulkan1:i386 \
libmpg123-dev \
libinput-dev \
libwine \
libvkd3d1 \
libz-mingw-w64 \
libwine \
libgtk-3-dev \ 
libpng-dev \
libeio1 \ 
libeinfo1 \
libx11-dev \
libxcomposite-dev \
libxrandr-dev \
libxext-dev \
libfreetype6-dev \
libxfixes-dev \
libssl-dev \
libvulkan-dev \
libasound2-dev \
libpcap-dev \
libsqlite3-dev \
libdbus-1-dev \
libopenal-dev \
libgl1-mesa-dev \
libv4l-dev \
libsdl2-dev \
libgphoto2-dev \
libodbc1 \
libgnutls28-dev

mkdir $PWD/.cache/
mkdir $PWD/.cache/wine

chown -R $USER:$USER $PWD

wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-mono/9.4.0/wine-mono-9.4.0-x86.msi
sudo -u $USER wine msiexec /i $PWD/.cache/wine/wine-mono-9.4.0-x86.msi

wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi
sudo -u $USER wine msiexec -i $PWD/.cache/wine/wine-gecko-2.47.4-x86_64.msi

sudo -u $USER winetricks \
forcemono \
directplay d3dx9_43 d3dcompiler_47 d3dx11_43 \
dxvk vkd3d dxvk2010 \
msxml3 msxml6 mfc140 \
dotnet472 dotnet48 \
mfc110 mfc120 mfc140 \
vcrun2019 vcrun2010 vcrun2015 \
xact devenum \
dsound windowscodecs dinput8 xinput \
mimeassoc=on \
richtx32 corefonts allfonts

sudo -u $USER wine winecfg -v win81
wget -P $PWD/.cache/wine https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
sudo -u $USER wine $PWD/.cache/wine/mt5setup.exe /auto
sudo -u $USER wine wineboot -u -f -r

find / | grep terminal64.exe
