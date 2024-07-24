apt install -y libpam-google-authenticator

apt install -y sudo xrdp ssl-cert
sudo adduser xrdp ssl-cert

path=/etc/pam.d/xrdp-sesman
mv $path $path.bkp
cat <<'EOF'>> $path
auth required pam_google_authenticator.so forward_pass
EOF

sudo systemctl restart xrdp

google-authenticator -t -D -W -C -f -r 3 -R 30
