#!/bin/bash
apt-get install -y curl > /dev/null
curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh 2>&1 | grep "E:"
INSTALLER="install.sh"

##############################
## Variáveis da Instalação  ##
##############################
ID=openmediavault
CODENAME=sandworm
URIS=http://packages.openmediavault.org/public

URI_KEY=$URIS/archive.key
COMPONENTS=$(curl -fsSL $URIS/dists/$CODENAME/Release | grep Components | cut -d ':' -f 2) 

PATH_FILE_SIGNED=/usr/share/keyrings/$ID-$CODENAME.gpg
PATH_FILE_SOURCE=/etc/apt/sources.list.d/$ID-$CODENAME.list

PACKAGES='systemd-timesyncd openvswitch-switch openmediavault'

export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

##############################
##    NOVOS REPOSITÓRIOS    ##
##############################
cat > ~/repo << EOF
#!/bin/bash
if [ ! -e $PATH_FILE_SOURCE ];
  then
  echo
  echo "[ Repositório $ID ]: Configurando ..."

cat > $PATH_FILE_SOURCE << EOL
deb [signed-by=$PATH_FILE_SIGNED] $URIS $CODENAME $COMPONENTS
EOL

wget --quiet --output-document=- $URI_KEY | gpg --dearmor --yes --output $PATH_FILE_SIGNED > /dev/null
sleep 2

  echo "[ Repositório $ID ]: OK!"
fi
EOF
sleep 2

#############################
##       Instalação        ##
#############################
echo
echo "[ $ID ]: Instalando ..."

if grep PACKAGE_NAME $INSTALLER > /dev/null
  then
    sed -i "s|PACKAGE_NAME|$PACKAGES|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
sleep 2

#############################
## Ajustes pós-Instalação  ##
#############################
echo "[ $ID ]: Reconfigurando Conexão de Rede ..."
sudo omv-salt deploy run systemd-networkd 2>&1 | grep "Ey:"
sleep 2

cat >> /etc/netplan/10-openmediavault-default.yaml << EOF
  ethernets:
    $(ip -br -4 a | grep UP | cut -d ' ' -f 1):
      dhcp4: true
EOF

if [ -e /etc/apt/sources.list ]
  then
rm /etc/apt/sources.list
fi
if [ -e /etc/apt/sources.list.d/openmediavault.list ]
  then
rm /etc/apt/sources.list.d/openmediavault.list
fi


sudo netplan apply 2>&1
echo "[ $ID ]: Conexão de Rede - OK!"
sleep 2

#############################
##        Conclusão        ##
#############################
echo "[ $ID ]: Instalação Concluída!"
echo
echo "Acesse http://$(hostname -I | cut -d ' ' -f 1)"
echo
echo "Login: admin"
echo "Senha: openmediavault"
echo

#echo
#echo "Buscando as últimas atualizações do OpenMediaVault..."
#echo
#sudo apt --only-upgrade install openmediavault
#sudo omv-upgrade
#echo
