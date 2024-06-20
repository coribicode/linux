
pwd=412190

CN=$(hostname)

ip4=$(hostname -I | cut -d '.' -f 4 | cut -d ' ' -f 1)
ip3=$(hostname -I | cut -d '.' -f 3 | cut -d ' ' -f 1)
ip2=$(hostname -I | cut -d '.' -f 2 | cut -d ' ' -f 1)
ip1=$(hostname -I | cut -d '.' -f 1 | cut -d ' ' -f 1)

apt -y install novnc python3-websockify
#openssl req -x509 -nodes -newkey rsa:3072 -keyout novnc.pem -out novnc.pem -days 3650

openssl req -x509 -nodes -newkey rsa:3072 -keyout $CN.pem -days 3650 -subj "/C=BR/ST=Parana/L=Curitiba/O=Virtual East/OU=Virtual Easy/CN=$CN" -addext "subjectAltName = DNS:$CN" -out $CN.pem
websockify -D --web=/usr/share/novnc/ --cert=$PWD/$CN.pem 6080 localhost:5901


apt -y install tigervnc-standalone-server
echo
echo "Cadastre a senha noVNC"
echo
vncserver
echo
sudo vncserver -kill :1

ls -l /usr/share/*sessions/
echo
ls -l /usr/bin/*session

cat <<"EOF">> $PWD/.vnc/config
session=lightdm-xsession
geometry=1024x768
localhostalwaysshared
EOF

echo ":1=$USER" >> /etc/tigervnc/vncserver.users

systemctl start tigervncserver@:1.service
systemctl enable tigervncserver@:1.service
systemctl status tigervncserver@:1.service

echo
echo "Acesse via browser https://$ip1.$ip2.$ip3.$ip4:6080/vnc.html"
echo
