DEBIAN_VERSION_CODENAME=$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2)

apt install sudo wget -y

sudo dpkg --add-architecture i386 
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/$DEBIAN_VERSION_CODENAME/winehq-$DEBIAN_VERSION_CODENAME.sources

sudo apt update
sudo apt install --install-recommends winehq-stable winetricks -y
