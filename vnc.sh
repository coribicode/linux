####################################
# INSTALAÇÃO DE ACESSO REMOTO VNC  #
####################################

####################################
## Altere a senha abaixo          ##
####################################

pwd=123

####################################

apt-get install x11vnc -y
cat << 'EOF' >> /lib/systemd/system/x11vnc.service
[Unit]
Description=x11vnc service
After=display-manager.service
network.target syslog.target
[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -forever -display :0 -auth guess -passwd $pwd 
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable x11vnc.service 
systemctl start x11vnc.service
