######################################
# Autenticação duplo Fator TOTP      #
######################################
GUAC_VERSION=$(sudo guacd -v | tr ' ' '\n' | grep -E [0-9])
#TOMCAT_VERSION=$(sh /usr/share/tomcat*/bin/version.sh | grep number | cut -d ':' -f2 | cut -d '.' -f1 | tr -d " ")

wget -P /opt/ https://dlcdn.apache.org/guacamole/"$GUAC_VERSION"/binary/guacamole-auth-totp-"$GUAC_VERSION".tar.gz
tar -zxf /opt/guacamole-auth-totp-"$GUAC_VERSION".tar.gz -C /opt/
cp /opt/guacamole-auth-totp-"$GUAC_VERSION"/guacamole-auth-totp-"$GUAC_VERSION".jar /etc/guacamole/extensions/

export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
sudo systemctl daemon-reload
sudo systemctl restart guacd
sudo systemctl restart tomcat*
