apt install -y libpam-google-authenticator

apt install -y sudo ssh ssl-cert
sudo adduser sshd ssl-cert

path=/etc/pam.d/sshd
mv $path $path.bkp
cat <<'EOF'>> $path
auth required pam_google_authenticator.so forward_pass
EOF

sudo systemctl restart sshd

echo "Execute o comando abaixo na sessão do usuário:"
echo
echo "google-authenticator -t -D -W -C -f -r 3 -R 30"
echo
echo "Sincronize o QRCode com seu App OTP preferido "
