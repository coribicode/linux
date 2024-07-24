apt install -y libpam-google-authenticator

apt install -y sudo xrdp ssl-cert
sudo adduser xrdp ssl-cert

path=/etc/pam.d/xrdp-sesman
mv $path $path.bkp
cat <<'EOF'>> $path
auth required pam_google_authenticator.so forward_pass
EOF

sudo systemctl restart xrdp

echo "Execute o comando abaixo na sessão do usuário"
echo
echo "google-authenticator -t -D -W -C -f -r 3 -R 30"
echo
echo "Sincronize o QRCode com seu OTP de preferência"
