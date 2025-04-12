#!/bin/sh
curl -fsSL https://raw.githubusercontent.com/davigalucio/linux/main/essentials.sh | sh
curl -fsSL https://raw.githubusercontent.com/davigalucio/linux/main/debian_repository.sh | sh 
curl -fsSL https://raw.githubusercontent.com/davigalucio/linux/main/wine-stable.sh | sh 

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
wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-mono/9.4.0/wine-mono-9.4.0-x86.msi > /dev/null 2>&1
sudo -u $USER WINEPREFIX="$winedir/.wine" wine msiexec /i $PWD/.cache/wine/wine-mono-9.4.0-x86.msi > /dev/null 2>&1
sleep 2
echo "[ $PATH_SOURCE  ]: OK!"
fi

PATH_SOURCE=$PWD/.cache/wine/wine-gecko-2.47.4-x86_64.msi
if [ -e $PATH_SOURCE ]
then
echo "[ $PATH_SOURCE  ]: OK!"
else
echo "[ $PATH_SOURCE  ]: Downloading..."
wget -P $PWD/.cache/wine https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi > /dev/null 2>&1
sudo -u $USER WINEPREFIX="$winedir/.wine" wine msiexec -i $PWD/.cache/wine/wine-gecko-2.47.4-x86_64.msi > /dev/null 2>&1
sleep 2
echo "[ $PATH_SOURCE  ]: OK!"
fi

PACKAGES="forcemono mimeassoc=on vkd3d dxvk2010 dxvk comctl32ocx comdlg32ocx corefonts d3dcompiler_42 d3dcompiler_43 d3dcompiler_46 d3dcompiler_47 d3drm d3dx10 d3dx10_43 d3dx11_42 d3dx11_43 d3dxof devenum dinput dinput8 directplay directx9 dmband dmcompos dmime dmloader dmscript  dmstyle  dmsynth dotnet40 dotnet45 dotnet452 dotnet46 dotnet461 dotnet462 dotnet471 dotnet472 dotnet48 dpvoice dsdmo dsound dswave dxdiag dxvk dxvk1103 dxvk2000 dxvk2010 esent faudio faudio1906 faudio190607 gdiplus mfc140 mfc80 mfc90 msaa msxml3 msxml4 msxml6 prntvpt richtx32 vcrun2005 vcrun2010 vcrun2015 vkd3d webio windowscodecs xact xinput xmllite xna40"

WINEPREFIX_PATH='WINEPREFIX="/opt/wine-stable/win64apps/.wine"'

curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install-winetricks.sh > /dev/null 2>&1
INSTALLER="install-winetricks.sh"

sed -i "s|WINEPREFIX_PATH|$WINEPREFIX_PATH|g" $INSTALLER

echo
echo "[ Instalação Winetricks ]: Inicio"
if grep PACKAGE_NAME $INSTALLER > /dev/null 2>&1
  then
    sed -i "s|PACKAGE_NAME|$PACKAGES|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ Instalação Winetricks ]: Fim."
echo

# ------- INSTALAÇÃO WINETRICKS ------- FIM

sudo -u $USER WINEPREFIX="$winedir/.wine" WINEARCH=win64 wine wineboot -u -f -r > /dev/null 2>&1
sudo -u $USER WINEPREFIX="$winedir/.wine" wineserver -k > /dev/null 2>&1
sudo -u $USER WINEPREFIX="$winedir/.wine" wine winecfg -v win81 > /dev/null 2>&1

PATH_SOURCE=$winedir/.cache/wine/mt5setup.exe
if [ -e $PATH_SOURCE ]
then
echo "[ $PATH_SOURCE  ]: OK!"
else
echo "[ $PATH_SOURCE  ]: Downloading..."
wget -P $winedir/.cache/wine https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe > /dev/null 2>&1
sudo -u $USER WINEPREFIX="$winedir/.wine" wine $winedir/.cache/wine/mt5setup.exe /auto > /dev/null 2>&1
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
