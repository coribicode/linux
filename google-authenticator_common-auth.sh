apt install -y libpam-google-authenticator

path=/etc/pam.d/common-auth
mv $path $path.bkp
cat <<'EOF'>> $path
auth required pam_google_authenticator.so forward_pass
EOF

sudo systemctl daemon-restart

echo "ATENÇÃO: Essa configuração adiciona duplo fator"
echo "em todo tipo de authenticação no sistema:"
echo "SSH SU XRDP ..."
echo
echo "Execute o comando abaixo na sessão do root e usuários"
echo
echo "google-authenticator -t -D -W -C -f -r 3 -R 30"
echo
echo "Sincronize o QRCode com seu OTP de preferência"
