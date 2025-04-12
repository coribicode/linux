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
apt install -y python3-dev python3-opengl python3-numpy python3-cairo-dev python3-pil python-gi-dev python3-dbus python3-cryptography python3-netifaces python3-yaml python3-rencode python3-paramiko python3-dnspython python3-zeroconf python3-netifaces python3-cups python3-gi-cairo python3-setproctitle python3-xdg python3-pyinotify

apt install -y lxterminal
# XPRA_APP=lxterminal

$XPRA_USER=user005
sudo useradd -m -s /bin/bash $XPRA_USER && echo "$XPRA_USER:123" | sudo chpasswd

sudo -u $XPRA_USER mkdir /run/user/$XPRA_USER
sudo -u $XPRA_USER chmod -R $XPRA_USER:$XPRA_USER /run/user/$XPRA_USER
sudo -u $XPRA_USER chmod -R 0700 /run/user/$XPRA_USER
sudo -u $XPRA_USER export XDG_RUNTIME_DIR=/run/user/$XPRA_USER
sudo -u $XPRA_USER export XPRA_APP=lxterminal 

sudo -u $XPRA_USER xpra start :100 \
 --bind-tcp=0.0.0.0:10000 \
 --start="$XPRA_APP" \
 --encodings=h264,vp9 \
 --quality=100 \
 --min-quality=80 \
 --speed=100 \
 --opengl=yes \
 --dpi=144 \
 --video-scaling=off \
 --no-pulseaudio \
 --env=XPRA_ALLOW_ROOT=1 \
 --no-mmap \
 --html=on \
 --env=XPRA_FORCE_COLOR_DEPTH=32 \
 --env=DISPLAY=:100 \
 --no-notifications \
 --socket-dir=$XDG_RUNTIME_DIR
  
sudo -u $USER xpra list

# sudo -u $USER xpra stop :100
# xpra start :100 --start-child=xclock --bind-tcp=0.0.0.0:10000 --html=on --start=xterm
# xpra start :100 --bind-tcp=0.0.0.0:10000 --html=on --start=xterm --env=XPRA_FORCE_COLOR_DEPTH=32   --env=DISPLAY=:100   --dpi=144
