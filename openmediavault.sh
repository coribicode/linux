apt_dist='openmediavault'

keyring_gpg_path="/usr/share/keyrings/"$apt_dist"-archive-keyring.gpg"

key_uri='https://packages.openmediavault.org/public/archive.key'

cat <<"EOL">> /opt/$apt_dist.list
deb [signed-by=keyring_gpg_path] http://packages.openmediavault.org/public/ sandworm main
deb [signed-by=keyring_gpg_path] https://openmediavault.github.io/packages/ sandworm main
EOL

cat "/opt/$apt_dist.list" >> /etc/apt/sources.list.d/$apt_dist.list

sed -i "s|keyring_gpg_path|$keyring_gpg_path|g" /etc/apt/sources.list.d/$apt_dist.list

apt-get install -y gnupg wget ntp

wget --quiet --output-document=- $key_uri | gpg --dearmor --yes --output "$keyring_gpg_path"

export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
apt-get update
apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault

ip=$(hostname -I | cut -d ' ' -f 1)

echo
echo "Acesse http://$ip"
echo
echo "Login: admin"
echi "Senha: openmediavault"
echo
