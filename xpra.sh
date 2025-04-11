apt update
apt upgrade -y
apt install git curl sudo apt-transport-https software-properties-common ca-certificates python3-distutils pkg-config -y
curl https://xpra.org/gpg.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/xpra.gpg
git clone https://github.com/Xpra-org/xpra
cd xpra
./setup.py install-repo
apt update
apt upgrade -y
apt install xpra xpra-client-gtk3 xpra-codecs-extras xpra-codecs xpra-common xpra-client xpra-audio xpra-codecs-extras xpra-x11 xpra-html5 xpra-server xpra-codecs-nvidia -y
apt install python3 python3-rencode python3-paramiko python3-dnspython python3-zeroconf python3-netifaces python3-cups python3 python3-gi-cairo dbus-x11 ibus python3-setproctitle python3-xdg python3-pyinotify gir1.2-rsvg-2.0 cups-filters cups-common cups-pdf cups-daemon libsystemd-dev libvpx7 libwebp7 -y

# xpra start :100 --start-child=xclock --bind-tcp=0.0.0.0:10000 --html=on --start=xterm
xpra start :100 --bind-tcp=0.0.0.0:10000 --html=on --start=xterm --env=XPRA_FORCE_COLOR_DEPTH=24   --env=DISPLAY=:100   --dpi=96

xpra list

# xpra stop :100
