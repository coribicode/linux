#!/bin/sh
DEBIAN_VERSION_CODENAME=$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2)

mkdir -pm755 /etc/apt/keyrings
wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/stable/winehq-$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2).sources

dpkg --add-architecture i386
apt update && apt upgrade -y && systemctl daemon-reload

# wine64-preloader wine64-tools 
apt install -y --install-recommends winehq-stable winetricks mono-complete fonts-wine wine-binfmt
apt install -y --install-recommends libc6-i386 zlib1g libxft2 libcairo2 libvulkan1 libpcl1 libpcl1-dev libvulkan1:i386 libmpg123-dev libinput-dev libwine libvkd3d1 libz-mingw-w64 libwine libgtk-3-dev libpng-dev libeio1 libeinfo1
apt install -y --install-recommends winbind ttf-mscorefonts-installer binfmt-support xorg xvfb gtk2-engines-pixbuf imagemagick xauth vulkan-tools
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

mkdir $PWD/.cache/
mkdir $PWD/.cache/wine

chown -R $USER:$USER $PWD

wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-mono/9.4.0/wine-mono-9.4.0-x86.msi
sudo -u $USER wine msiexec /i $PWD/.cache/wine/wine-mono-9.4.0-x86.msi

wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi
sudo -u $USER wine msiexec -i $PWD/.cache/wine/wine-gecko-2.47.4-x86_64.msi

sudo -u $USER winetricks forcemono dxvk corefonts xinput msxml3 msxml6 mfc140 dsound mimeassoc=on windowscodecs
sudo -u $USER winetricks -q dotnet48 
sudo -u $USER winetricks -q vcrun2010
sudo -u $USER winetricks -q mfc110 mfc120 mfc140 
sudo -u $USER winetricks -q directx9 directplay dxvk2010 directshow  dsound  d3dx9_43 d3dx11_43 d3dcompiler_47
sudo -u $USER winetricks -q xact dinput8 vkd3d allfonts xact_x64 wininet winhttp richtx32 quartz oleaut32 ole32

sudo -u $USER wine winecfg -v win11
wget -P $PWD/.cache/wine https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
sudo -u $USER wine $PWD/.cache/wine/mt5setup.exe /auto
sudo -u $USER wine wineboot -u

# sudo -u $USER wine wineboot -u -f -r

find / | grep terminal64.exe
