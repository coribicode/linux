####################################
# INSTALAÇÃO DE ACESSO REMOTO VNC  #
####################################

####################################
## Altere a senha abaixo          ##
####################################

passwdvnc=123

####################################

apt-get install x11vnc -y

mkdir $PWD/.vnc
echo $passwdvnc | vncpasswd -f > $PWD/.vnc/passwd
chown -R $USER:$USER $PWD/.vnc
chmod 0600 $PWD/.vnc/passwd

cat << 'EOF' >> /lib/systemd/system/x11vnc.service
[Unit]
Description=x11vnc service
After=display-manager.service
network.target syslog.target
[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -forever -display :0 -auth guess
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable x11vnc.service 
systemctl start x11vnc.service
