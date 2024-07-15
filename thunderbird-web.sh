##############################
# Instalação de Essenciais  ##
##############################

apt-get update
apt-get --no-install-recommends install xorg lightdm lxde-core xrdp -y

##############################
# Instalação do thunderbird ##
##############################

apt-get install thunderbird thunderbird-l10n-pt-br -y

##############################
# Loop do thunderbird       ## 
##############################

cat << 'EOF' > /opt/thunderbird-loop.sh
# Inicia o Thunderbird em loop no logon do sistema
i=0
while [ $i -ne 999 ]
do
    i=$(($i+1))
    thunderbird --maximized
done
EOF

chmod +x /opt/thunderbird-loop.sh

###########################################
# Bloqueio da Proteção de Tela do Linux  ##
###########################################

mv /etc/xdg/lxsession/LXDE/autostart /etc/xdg/lxsession/LXDE/autostart.bkp

# Criando no arquivo autostart
cat << 'EOF' > /etc/xdg/lxsession/LXDE/autostart
#Scrpit do Painel Inicial
#Desativa bloqueio automático de tela, proteção de tela
@xset s noblack
@xset s off
@xset -dpms
# Executa o script do loop do thunderbird
sh /opt/thunderbird-loop.sh
EOF

################################################################
# Menu de acesso ao Thunderbird com o botao direito do mouse  ##
################################################################

mv /etc/xdg/openbox/menu.xml /etc/xdg/openbox/menu.xml.bkp

# Criando menu do botão direito do mouse na área de trabalho
mv /etc/xdg/openbox/menu.xml /etc/xdg/openbox/menu.xml.bkp
cat << 'EOF' > /etc/xdg/openbox/menu.xml
<?xml version="1.0" encoding="UTF-8"?>
 <openbox_menu xmlns="http://openbox.org/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://openbox.org/
  file:///usr/share/openbox/menu.xsd">
  <menu id="root-menu" label="Openbox 3">
      <item label="thunderbird">
        <action name="Execute"><execute>Thunderbird</execute></action>
      </item>
    <separator />
      <item label="Sair">
        <action name="Execute"><execute>bash -c "pkill -KILL -u $USER"</execute></action>
      </item>
  </menu>
</openbox_menu>
EOF
