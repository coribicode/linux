#####################
## Prioridade IPV4 ##
#####################
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

nic=$(ip -4 link | grep "state UP" | cut -d ':' -f 2 | tr -d ' ')
mac=$(ip add | grep link/ether | awk '{print $2}')

apt_dist='openmediavault'

keyring_gpg_path="/usr/share/keyrings/"$apt_dist"-archive-keyring.gpg"

key_uri='https://packages.openmediavault.org/public/archive.key'

ip=$(hostname -I | cut -d ' ' -f 1)

cat <<"EOL">> /opt/$apt_dist.list
deb [signed-by=keyring_gpg_path] http://packages.openmediavault.org/public/ sandworm main
deb [signed-by=keyring_gpg_path] https://openmediavault.github.io/packages/ sandworm main
EOL

cat "/opt/$apt_dist.list" >> /etc/apt/sources.list.d/$apt_dist.list

sed -i "s|keyring_gpg_path|$keyring_gpg_path|g" /etc/apt/sources.list.d/$apt_dist.list

apt-get install -y wget gnupg sudo systemd-timesyncd ca-certificates

wget --quiet --output-document=- $key_uri | gpg --dearmor --yes --output "$keyring_gpg_path"

## Lista as KEY
sudo dpkg -l | grep keyring

apt update && apt upgrade -y

networkctl

export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
apt-get update
apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault openvswitch-switch-dpdk

sudo omv-salt deploy run systemd-networkd

cp /etc/netplan/10-openmediavault-default.yaml /etc/netplan/10-openmediavault-default.yaml.bkp

cat <<"EOF">> /etc/netplan/10-openmediavault-default.yaml
  ethernets:
   eth0:
     dhcp4: true
EOF

sudo netplan apply

/etc/init.d/networking restart

networkctl

echo
echo "Buscando as últimas atualizações do OpenMediaVault..."
echo
sudo apt --only-upgrade install openmediavault
sudo omv-upgrade
echo

echo
echo "Acesse http://$ip"
echo
echo "Login: admin"
echo "Senha: openmediavault"
echo
