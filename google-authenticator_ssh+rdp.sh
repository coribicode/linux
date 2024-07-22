apt install -y libpam-google-authenticator

path=/etc/ssh/sshd_config
cp $path $path.bkp
sudo sed -i 's|UsePAM no|UsePAM yes|g' $path
sudo sed -i 's|KbdInteractiveAuthentication no|KbdInteractiveAuthentication yes|g' $path
sudo systemctl restart sshd

path=/etc/pam.d/common-auth
cp $path $path.bkp
sudo sed -i 's|"Primary" block)|"Primary" block)\
auth    required                        pam_google_authenticator.so|g' $path

apt install -y xrdp

path=/etc/pam.d/xrdp-sesman
mv $path $path.bkp

cat <<'EOF'>> $path
auth required pam_google_authenticator.so forward_pass
EOF
