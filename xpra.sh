apt-get update > /dev/null | grep "E:"
apt-get upgrade -y > /dev/null | grep "E:"

INSTALLING(){
apt-get install -y curl 2>/dev/null | grep "E:"
curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh 2>/dev/null | grep "E:"
INSTALLER="install.sh"

package_list="$PACKAGES_DEPENDECES"

echo
echo "[ $NAME_PACKAGE ]: Instalando pacotes... "
if grep PACKAGE_NAME $INSTALLER > /dev/null
  then
    sed -i "s|PACKAGE_NAME|$package_list|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ $NAME_PACKAGE ]: OK!"
echo
sleep 2
}

NAME_PACKAGE="ESSENTIALS"
PACKAGES_DEPENDECES="git curl wget sudo apt-transport-https software-properties-common ca-certificates pkg-config"
INSTALLING

NAME_PACKAGE="PYTHON"
PACKAGES_DEPENDECES="python3-distutils python3-pip python3-dev python3-opengl python3-numpy python3-cairo-dev python3-pil python-gi-dev python3-dbus python3-cryptography python3-netifaces python3-yaml python3-rencode python3-paramiko python3-dnspython python3-zeroconf python3-netifaces python3-cups python3-gi-cairo python3-setproctitle python3-xdg python3-pyinotify"
INSTALLING
sudo -u $USER pip3 install --user --break-system-packages PyOpenGL_accelerate

NAME_PACKAGE="OTHERS PACKAGES"
PACKAGES_DEPENDECES="gstreamer1.0-pulseaudio gstreamer1.0-alsa gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly vainfo dbus-x11 ibus ibus-gtk3 ibus-pinyin uglifyjs quilt xserver-xorg-dev xutils-dev xserver-xorg-video-dummy xvfb keyboard-configuration brotli gir1.2-rsvg-2.0 yasm cython3 devscripts build-essential lintian debhelper pandoc gnome-backgrounds openssh-client sshpass"
INSTALLING

NAME_PACKAGE="XPRA LIBS"
PACKAGES_DEPENDECES="libva-drm2 libva-x11-2 libva-drm2 libva-x11-2 libpam-dev libjs-jquery libjs-jquery-ui libnvidia-encode1 libx264-dev libvpx-dev libturbojpeg-dev libwebp-dev libgtk-3-dev libsystemd-dev libvpx7 libwebp7 libx11-dev libxtst-dev libxcomposite-dev libxdamage-dev libxres-dev libxkbfile-dev liblz4-dev"
INSTALLING

NAME_PACKAGE="XPRA DRIVERS"
PACKAGES_DEPENDECES="i965-va-driver x264 va-driver-all vdpau-driver-all intel-media-va-driver-non-free"
INSTALLING

FILE_GPG=/etc/apt/trusted.gpg.d/xpra.gpg
if [ -e $FILE_GPG ]
then
echo "[ $FILE_GPG ]: Arquivo já existe!"
else
curl https://xpra.org/gpg.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/xpra.gpg > /dev/null
git clone https://github.com/Xpra-org/xpra > /dev/null
cd xpra
./setup.py install-repo
apt update
fi

NAME_PACKAGE="XPRA"
PACKAGES_DEPENDECES="xpra xpra-client-gtk3 xpra-codecs-extras xpra-codecs xpra-common xpra-client xpra-audio xpra-codecs-extras xpra-x11 xpra-html5 xpra-server xpra-codecs-nvidia"
INSTALLING
xpra --version
