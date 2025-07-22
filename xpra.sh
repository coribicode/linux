apt update
apt upgrade -y
apt install git curl wget sudo apt-transport-https software-properties-common ca-certificates python3-distutils pkg-config -y
curl https://xpra.org/gpg.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/xpra.gpg
git clone https://github.com/Xpra-org/xpra
cd xpra
./setup.py install-repo
apt update
apt install -y xpra xpra-client-gtk3 xpra-codecs-extras xpra-codecs xpra-common xpra-client xpra-audio xpra-codecs-extras xpra-x11 xpra-html5 xpra-server xpra-codecs-nvidia
apt install -y dbus-x11 ibus uglifyjs quilt xserver-xorg-dev xutils-dev xserver-xorg-video-dummy xvfb keyboard-configuration brotli gir1.2-rsvg-2.0 yasm cython3 devscripts build-essential lintian debhelper pandoc gnome-backgrounds openssh-client sshpass
apt install -y gstreamer1.0-pulseaudio gstreamer1.0-alsa gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly
apt install -y libpam-dev libjs-jquery libjs-jquery-ui libnvidia-encode1 libx264-dev libvpx-dev libturbojpeg-dev libwebp-dev libgtk-3-dev libsystemd-dev libvpx7 libwebp7 libx11-dev libxtst-dev libxcomposite-dev libxdamage-dev libxres-dev libxkbfile-dev liblz4-dev
apt install -y python3-pip python3-dev python3-opengl python3-numpy python3-cairo-dev python3-pil python-gi-dev python3-dbus python3-cryptography python3-netifaces python3-yaml python3-rencode python3-paramiko python3-dnspython python3-zeroconf python3-netifaces python3-cups python3-gi-cairo python3-setproctitle python3-xdg python3-pyinotify
apt install -y vainfo libva-drm2 libva-x11-2 i965-va-driver x264 va-driver-all vdpau-driver-all libva-drm2 libva-x11-2 intel-media-va-driver-non-free ibus-gtk3 ibus-pinyin
sudo -u $USER pip3 install --user --break-system-packages PyOpenGL_accelerate

xpra --version
