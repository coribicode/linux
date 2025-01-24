DEBIAN_VERSION_CODENAME=$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2)

mkdir -pm755 /etc/apt/keyrings
wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/stable/winehq-$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2).sources

dpkg --add-architecture i386
apt update && apt upgrade -y && systemctl daemon-reload

apt install -y --install-recommends winehq-stable winetricks mono-complete wine64-preloader wine64-tools fonts-wine wine-binfmt
apt install -y --install-recommends libc6-i386 zlib1g libxft2 libcairo2 libvulkan1 libpcl1 libpcl1-dev libvulkan1:i386 libmpg123-dev libinput-dev libwine libvkd3d1 libz-mingw-w64 libwine libgtk-3-dev libpng-dev libeio1 libeinfo1
apt install -y --install-recommends winbind ttf-mscorefonts-installer binfmt-support xorg xvfb gtk2-engines-pixbuf imagemagick xauth vulkan-tools
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

mkdir $PWD/.cache/
mkdir $PWD/.cache/wine

wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-mono/9.4.0/wine-mono-9.4.0-x86.msi
sudo -u $USER wine msiexec /i $PWD/.cache/wine/wine-mono-9.4.0-x86.msi

wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi
sudo -u $USER wine msiexec -i $PWD/.cache/wine/wine-gecko-2.47.4-x86_64.msi

sudo -u $USER winetricks forcemono

sudo -u $USER winetricks dxvk corefonts xinput msxml3 msxml6 mfc140 dsound mimeassoc=on windowscodecs

sudo -u $USER wine winecfg -v win11 wineboot -u -f -r

wget -P $PWD/.cache/wine https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
sudo -u $USER wine $PWD/.cache/wine/mt5setup.exe /auto

# sudo -u $USER wine cmd.exe /c "$(find / | grep terminal64.exe)"

## --button="Chromium:chromium --disable-gpu --no-sandbox --disable-gpu-rasterization --disable-software-rasterizer" \

apt install yad at-spi2-core chromium lxtask -y

cat << EOF > /opt/painel
#!/bin/bash
# Criação do painel com três botões
yad --window-icon="gtk-execute" --image="debian-logo" --item-separator="," \
    --title "PainelX11" \
    --form --borders=100 --center --columns=1 --height=450 --width=550 --no-buttons \
    --field 'Chromium:BTN' 'chromium --no-sandbox' \
    --field 'Gerenciador de Tarefas:BTN' 'lxtask' \
    --button="Chromium:chromium --no-sandbox" \
    --button="Meta Trader 5:wine /home/user/.wine/drive_c/Program\ Files/MetaTrader\ 5/terminal64.exe" \
    --button="Gerenciador de Tarefas:lxtask" \
    --center \
    --fixed \
    --text="Escolha uma opção:" \
    --buttons-layout=center \
EOF
