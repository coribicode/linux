apt_dist=openmediavault
keyring_gpg_path=/usr/share/keyrings/$apt_dist-archive-keyring.gpg
key_uri='https://packages.openmediavault.org/public/archive.key'
FILE=/etc/apt/sources.list.d/$apt_dist.list
NIC=$(ip -br -4 a | grep UP | cut -d ' ' -f 1)
IP=$(hostname -I | cut -d ' ' -f 1)

clear

## Prioridade IPV4 ##
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

echo
echo "[ Dependências ]: Instalando ..."
apt-get install -y wget gnupg sudo systemd-timesyncd ca-certificates > /dev/null
echo "[ Dependências ]: OK!"
sleep 2

echo
echo "[ Repositórios ]: Verificando ..."
sleep 2
if [ -e $FILE ]
  then
    echo "[ Repositórios ]: OK!"
  else
    echo "[ Repositórios ]: Configurando ..."
cat > $FILE << EOF
deb [signed-by=$keyring_gpg_path] http://packages.openmediavault.org/public/ sandworm main
deb [signed-by=$keyring_gpg_path] https://openmediavault.github.io/packages/ sandworm main
EOF
wget --quiet --output-document=- $key_uri | gpg --dearmor --yes --output "$keyring_gpg_path" > /dev/null
    echo "[ Repositórios ]: OK!"
fi
sleep 2

echo
echo "[ Sistema ]: Atualizando ..."
apt-get update > /dev/null
apt-get upgrade -y > /dev/null
systemctl daemon-reload
echo "[ Sistema ]: OK!"
sleep 2

echo
echo "[OpenMediaVault]: Instalando OpenMediaVault ..."
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault openvswitch-switch 2>&1 | grep "E:"
sleep 2

echo "[ OpenMediaVault ]: Reconfigurando Conexão de Rede ..."
#sudo omv-salt deploy run systemd-networkd 2>&1 | grep -E "Succeeded|Failed"
sleep 2

cat >> /etc/netplan/10-openmediavault-default.yaml << EOF
  ethernets:
    $NIC:
      dhcp4: true
EOF
sudo netplan apply 2>&1
echo "[ OpenMediaVault ]: Conexão de Rede - OK!"
sleep 2

echo
echo "[ OpenMediaVault ]: Instalação Concluída!"
echo
echo "Acesse http://$IP"
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
