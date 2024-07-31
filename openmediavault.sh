apt_dist=openmediavault
keyring_gpg_path=/usr/share/keyrings/$apt_dist-archive-keyring.gpg
key_uri='https://packages.openmediavault.org/public/archive.key'
FILE=/etc/apt/sources.list.d/$apt_dist.list
NIC=$(ip -br -4 a | grep UP | cut -d ' ' -f 1)

## Prioridade IPV4 ##
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

echo
echo "[OpenMediaVault]: Instalando dependências..."
apt-get install -y wget gnupg sudo systemd-timesyncd ca-certificates > /dev/null
echo "[OpenMediaVault]: Verificando repositórios ..."
sleep 2

if [ -e $FILE ]
  then
    echo "[OpenMediaVault]: Repositórios - OK!"
  else
    echo "[OpenMediaVault]: Atualizando repositórios ..."
cat > $FILE << EOF
deb [signed-by=$keyring_gpg_path] http://packages.openmediavault.org/public/ sandworm main
deb [signed-by=$keyring_gpg_path] https://openmediavault.github.io/packages/ sandworm main
EOF
wget --quiet --output-document=- $key_uri | gpg --dearmor --yes --output "$keyring_gpg_path" > /dev/null
    echo "[OpenMediaVault]: Repositórios - OK!"
fi
sleep 2

echo "[OpenMediaVault]: Atualizando o Sistema ..."
apt-get update > /dev/null
apt-get upgrade -y > /dev/null
systemctl daemon-reload
echo "[OpenMediaVault]: Sistema - OK!"
sleep 2

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

echo "[OpenMediaVault]: Reconfigurando Conexão de Rede ..."
sudo omv-salt deploy run systemd-networkd 2>&1
sleep 2
ls /etc/netplan/
sleep 2
cat >> /etc/netplan/10-openmediavault-default.yaml << "EOF"
  ethernets:
    $NIC:
      dhcp4: true
EOF
sudo netplan apply > /dev/null
echo "[OpenMediaVault]: Conexão de Rede - OK!"
sleep 2

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
