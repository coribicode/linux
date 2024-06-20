
pwd=412190

ip4=$(hostname -I | cut -d '.' -f 4 | cut -d ' ' -f 1)
ip3=$(hostname -I | cut -d '.' -f 3 | cut -d ' ' -f 1)
ip2=$(hostname -I | cut -d '.' -f 2 | cut -d ' ' -f 1)
ip1=$(hostname -I | cut -d '.' -f 1 | cut -d ' ' -f 1)


apt -y install novnc python3-websockify
openssl req -x509 -nodes -newkey rsa:3072 -keyout novnc.pem -out novnc.pem -days 3650

websockify -D --web=/usr/share/novnc/ --cert=/home/$USER/novnc.pem 6080 localhost:5901


apt -y install tigervnc-standalone-server
echo $pwd|$pwd && vncserver
sudo vncserver -kill :*

ls -l /usr/share/*sessions/
ls -l /usr/bin/*session

cat <<EOF>> /root/.vnc/config
session=lightdm-xsession
geometry=1024x768
localhostalwaysshared
EOF

echo ":0=$USER" >> /etc/tigervnc/vncserver.users

systemctl start tigervncserver@:1.service
systemctl enable tigervncserver@:1.service
systemctl status tigervncserver@:1.service

mkdir /home/$USER/.vnc
echo $pwd | vncpasswd -f > /home/$USER/.vnc/passwd
chown -R $USER:$USER /home/$USER/.vnc
chmod 0600 /home/$USER/.vnc/passwd

echo 'Cadastre a senha noVNC"

echo
echo "Acesse via browser http://$ip1.$ip2.$ip3.$ip4:6080/vnc.html"
echo
