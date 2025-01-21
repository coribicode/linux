DEBIAN_VERSION_CODENAME=$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2)

apt install sudo wget -y

mkdir -pm755 /etc/apt/keyrings
wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/stable/winehq-$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2).sources

dpkg --add-architecture i386
apt update && apt upgrade -y && systemctl daemon-reload

apt install -y --install-recommends winehq-stable winetricks mono-complete winbind ttf-mscorefonts-installer winbind
apt install -y --install-recommends libc6-i386 zlib1g libx11-6 libxft2 libcairo2 libvulkan1
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

mkdir /opt/wine/
mkdir /opt/wine/downloads

mkdir /opt/wine/wineprofile/
mkdir /opt/wine/wineprofile/$USER

WINEPREFIX="/opt/wine/wineprofile/$USER/" W_DRIVE_C=/opt/wine/driver_c wine winecfg -v=win10 wineboot -u -f -r

wget -P /opt/wine/downloads https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi
WINEPREFIX="/opt/wine/wineprofile/$USER/" wine msiexec /i /opt/wine/downloads/wine-gecko-2.47.4-x86_64.msi

wget -P /opt/wine/downloads https://dl.winehq.org/wine/wine-mono/9.4.0/wine-mono-9.4.0-x86.msi
WINEPREFIX="/opt/wine/wineprofile/$USER/" wine msiexec /i /opt/wine/downloads/wine-mono-9.4.0-x86.msi

chown -R $USER:$USER /opt/wine/wineprofile/$USER
chown -R $USER:$USER /opt/wine/driver_c

winetricks dxvk d3dx9 dotnet481 mfc40 vcrun6 vcrun2012 vcrun2015

wget -P /opt/wine/downloads https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe

WINEPREFIX="/opt/wine/wineprofile/$USER/" W_DRIVE_C="/opt/wine/driver_c"  wine msiexec /i /opt/wine/downloads/mt5setup.exe


# WINEARCH=win32 WINEPREFIX="/opt/wineprofile/$USER/.wine" WINEARCH=win32 wine wineboot winecfg -v=win10
# WINEPREFIX=~"/opt/wineprofile/$USER/.wine" winecfg -v=win10
WINEPREFIX="$HOME/prefix32" WINEARCH=win32 wine wineboot -u -f -r

# wget -P /opt/ https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5debian.sh
# chmod +x /opt/mt5debian.sh

#  

mv /etc/xdg/lxsession/LXDE/autostart /etc/xdg/lxsession/LXDE/autostart.bkp

cat << 'EOF' > /etc/xdg/lxsession/LXDE/autostart
#Scrpit do Painel Inicial
#Desativa bloqueio automático de tela, proteção de tela
@xset s noblack
@xset s off
@xset -dpms
EOF

mv /etc/xdg/openbox/menu.xml /etc/xdg/openbox/menu.xml.bkp
# Criando no arquivo menu.xml
cat << 'EOF' > /etc/xdg/openbox/menu.xml
<?xml version="1.0" encoding="UTF-8"?>
 <openbox_menu xmlns="http://openbox.org/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://openbox.org/
  file:///usr/share/openbox/menu.xsd">
  <menu id="root-menu" label="Openbox 3">
      <item label="Instalar MT5">
        <action name="Execute"><execute>sh /opt/./mt5debian.sh</execute></action>
      </item>
    <separator />
      <item label="Metatrader 5">
        <action name="Execute"><execute>wine /home/user/.mt5/drive_c/Program\ Files/MetaTrader\ 5/terminal64.exe</execute></action>
      </item>
    <separator />
      <item label="Sair">
        <action name="Execute"><execute>bash -c "pkill -KILL -u $USER"</execute></action>
      </item>   
  </menu>
</openbox_menu>
EOF

sudo reboot
