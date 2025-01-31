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
wine-devel \
mono-complete \
fonts-wine \
wine-binfmt

# winehq-devel \
# wine-devel-dev \

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
libgnutls28-dev \
libwine-dev \
libkwineffects14 

mkdir /opt/wine-stable/win64apps
winedir=/opt/wine-stable/win64apps
chown -R $USER:$USER $winedir

mkdir $PWD/.cache
mkdir $PWD/.cache/wine
chown -R $USER:$USER $PWD

wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-mono/9.4.0/wine-mono-9.4.0-x86.msi
sudo -u $USER WINEPREFIX="$winedir/.wine" wine msiexec /i $PWD/.cache/wine/wine-mono-9.4.0-x86.msi

wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi
sudo -u $USER WINEPREFIX="$winedir/.wine" wine msiexec -i $PWD/.cache/wine/wine-gecko-2.47.4-x86_64.msi

sudo -u $USER WINEPREFIX="$winedir/.wine" winetricks -q \
forcemono \
mimeassoc=on \

# allfonts \
sleep 3
sudo -u $USER WINEPREFIX="$winedir/.wine" winetricks -q \
vcrun2010 vcrun2015 \
dotnet48 \
msxml3 msxml6 \
mfc140 \
directplay d3dx9 d3dx9_43 d3dx11_43 d3dcompiler_43 d3dcompiler_47 \
dsound windowscodecs dinput8 xinput \
xact devenum \
richtx32 corefonts \
vkd3d dxvk2010 dxvk | grep -w installed

sudo -u $USER WINEPREFIX="$winedir/.wine" WINEARCH=win64 wine wineboot -u -f -r
sudo -u $USER WINEPREFIX="$winedir/.wine" wineserver -k
sudo -u $USER WINEPREFIX="$winedir/.wine" wine winecfg -v win10

wget -P $winedir/.cache/wine https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
sudo -u $USER WINEPREFIX="$winedir/.wine" wine $winedir/.cache/wine/mt5setup.exe /auto

find / | grep terminal64.exe
