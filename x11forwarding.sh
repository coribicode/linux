PACKAGES_DEPENDECES="alsa-utils pulseaudio pulseaudio-module-zeroconf firmware-linux dbus-x11 x11-apps x11-xfs-utils s3dx11gate libx11-freedesktop-desktopentry-perl librust-x11-dev librust-x11rb-dev libx11-6 libx11-dev clang"

apt install -y curl 2>/dev/null | grep "E:"
curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh 2>/dev/null | grep "E:"
INSTALLER="install.sh"

package_list="$PACKAGES_DEPENDECES"
echo
echo "[ Instalação de Pacotes ]"
if grep PACKAGE_NAME $INSTALLER > /dev/null
  then
    sed -i "s|PACKAGE_NAME|$package_list|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ Instalação de Pacotes ]: OK!"
sleep 2

sudo -u $USER pulseaudio --start
sudo usermod -aG audio $USER

FILE_PULSE=/etc/pulse/default.pa
if [ -e $FILE_PULSE ]
then
cp $FILE_PULSE $FILE_PULSE.bkp
ADD_CONFIG="#load-module module-native-protocol-tcp"
if grep "$ADD_CONFIG" $FILE_PULSE
then
sed -i "s|$ADD_CONFIG|$(echo $ADD_CONFIG | sed 's/#//g')|g" $FILE_PULSE
fi
ADD_CONFIG="#load-module module-zeroconf-publish"
if grep "$ADD_CONFIG" $FILE_PULSE
then
sed -i "s|$ADD_CONFIG|$(echo $ADD_CONFIG | sed 's/#//g')|g" $FILE_PULSE
fi
else
echo "[ $FILE_PULSE ]: Não encontrado!"
fi

FILE_PULSE=/etc/pulse/daemon.conf
if [ -e $FILE_PULSE ]
then
cp $FILE_PULSE $FILE_PULSE.bkp
ADD_CONFIG="; realtime-scheduling = yes"
if grep "$ADD_CONFIG" $FILE_PULSE
then
sed -i "s|$ADD_CONFIG|$(echo $ADD_CONFIG | sed 's/; //g')|g" $FILE_PULSE
fi
ADD_CONFIG="; default-fragments = 4"
if grep "$ADD_CONFIG" $FILE_PULSE
then
sed -i "s|$ADD_CONFIG|$(echo $ADD_CONFIG | sed 's/; //g')|g" $FILE_PULSE
fi
ADD_CONFIG="; default-fragment-size-msec = 25"
if grep "$ADD_CONFIG" $FILE_PULSE
then
sed -i "s|$ADD_CONFIG|$(echo $ADD_CONFIG | sed 's/; //g')|g" $FILE_PULSE
fi
else
echo "[ $FILE_PULSE ]: Não encontrado!"
fi

sudo -u $USER pulseaudio -k
sudo -u $USER pulseaudio --start

FILE_SSHD_CONFIG=/etc/ssh/sshd_config
if [ -e $FILE_SSHD_CONFIG ]
then
cp $FILE_SSHD_CONFIG $FILE_SSHD_CONFIG.bkp
ADD_CONFIG_SSHD="#AllowAgentForwarding yes"
if grep "$ADD_CONFIG_SSHD" $FILE_SSHD_CONFIG
then
sed -i "s|$ADD_CONFIG_SSHD|$(echo $ADD_CONFIG_SSHD | sed 's/#//g')|g" $FILE_SSHD_CONFIG
fi
ADD_CONFIG_SSHD="#AllowTcpForwarding yes"
if grep "$ADD_CONFIG_SSHD" $FILE_SSHD_CONFIG
then
sed -i "s|$ADD_CONFIG_SSHD|$(echo $ADD_CONFIG_SSHD | sed 's/#//g')|g" $FILE_SSHD_CONFIG
fi
ADD_CONFIG_SSHD="#X11Forwarding yes"
if grep "$ADD_CONFIG_SSHD" $FILE_SSHD_CONFIG
then
sed -i "s|$ADD_CONFIG_SSHD|$(echo $ADD_CONFIG_SSHD | sed 's/#//g')|g" $FILE_SSHD_CONFIG
fi
ADD_CONFIG_SSHD="#X11UseLocalhost yes"
if grep "$ADD_CONFIG_SSHD" $FILE_SSHD_CONFIG
then
sed -i "s|$ADD_CONFIG_SSHD|$(echo $ADD_CONFIG_SSHD | sed 's/#//g')|g" $FILE_SSHD_CONFIG
fi
else
echo "[ $FILE_VAR ]: Não encontrado!"
fi

FILE_VAR="/etc/environment"
if [ -e $FILE_VAR ]
then
cp $FILE_VAR $FILE_VAR.bkp

ADD_VAR="LIBGL_ALWAYS_SOFTWARE=1"
if grep "$ADD_VAR" $FILE_VAR  > /dev/null
then
echo "VAR $ADD_VAR: Variavel já cadastrado!"
else
echo "$ADD_VAR" >> $FILE_VAR 
fi

ADD_VAR="MOZ_WEBGL_DISABLE_UNSAFE=1"
if grep "$ADD_VAR" $FILE_VAR > /dev/null
then
echo "VAR $ADD_VAR: Variavel já cadastrado!"
else
echo "$ADD_VAR" >> $FILE_VAR 
fi

else
echo "[ $FILE_VAR ]: Não encontrado!"
fi

source /etc/environment

systemctl restart sshd
systemctl daemon-reload

" ---------------------------------------------------------------------------------------------
