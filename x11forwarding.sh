# -- Configurações para passagem de som via X11 Forwarding ------------------------------------

apt install -y alsa-utils pulseaudio pulseaudio-module-zeroconf firmware-linux dbus-x11 x11-apps x11-xfs-utils s3dx11gate
apt install -y libx11-freedesktop-desktopentry-perl librust-x11+xinput-dev  librust-x11rb+xinput-dev libx11-6 libx11-dev clang
sudo -u $USER pulseaudio --start
sed -i 's|#load-module module-native-protocol-tcp|load-module module-native-protocol-tcp|g' /etc/pulse/default.pa
sed -i 's|#load-module module-zeroconf-publish|load-module module-zeroconf-publish|g' /etc/pulse/default.pa
sudo usermod -aG audio $USER

cat << EOF >> /etc/pulse/daemon.conf
realtime-scheduling = yes
default-fragments = 4
default-fragment-size-msec = 25
EOF

sudo -u $USER pulseaudio -k
sudo -u $USER pulseaudio --start

sed -i 's|#AllowAgentForwarding yes|AllowAgentForwarding yes|g' /etc/ssh/sshd_config
sed -i 's|#AllowTcpForwarding yes|AllowTcpForwarding yes|g' /etc/ssh/sshd_config
sed -i 's|#X11Forwarding yes|X11Forwarding yes|g' /etc/ssh/sshd_config
sed -i 's|#X11UseLocalhost yes|X11UseLocalhost yes|g' /etc/ssh/sshd_config

ADD_VAR="LIBGL_ALWAYS_SOFTWARE=1"
if grep $ADD_VAR /etc/environment > /dev/null
then
echo "VAR LIBGL_ALWAYS_SOFTWARE: Variavel já cadastrado!"
else
echo "LIBGL_ALWAYS_SOFTWARE=1" >> /etc/environment 
fi

ADD_VAR="MOZ_WEBGL_DISABLE_UNSAFE=1"
if grep "$ADD_VAR" /etc/environment > /dev/null
then
echo "VAR LIBGL_ALWAYS_SOFTWARE: Variavel já cadastrado!"
else
echo "MOZ_WEBGL_DISABLE_UNSAFE=1" >> /etc/environment 
fi

source /etc/environment

systemctl restart sshd
systemctl daemon-reload

" ---------------------------------------------------------------------------------------------
