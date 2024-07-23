apt install -y libpam-google-authenticator

#################################
# Para todo acesso SSH          #
#################################
apt install -y sshd

path=/etc/ssh/sshd_config
cp $path $path.bkp
sudo sed -i 's|UsePAM no|UsePAM yes|g' $path
sudo sed -i 's|KbdInteractiveAuthentication no|KbdInteractiveAuthentication yes|g' $path
sudo systemctl restart sshd

#################################
# Para todo acesso RDP com xrdp #
#################################
apt install -y xrdp

path=/etc/pam.d/xrdp-sesman
mv $path $path.bkp
cat <<'EOF'>> $path
auth required pam_google_authenticator.so forward_pass
EOF

#################################
# Para todo sistema             #
#################################
path=/etc/pam.d/common-auth
cp $path $path.bkp
sudo sed -i 's|"Primary" block)|"Primary" block)\
auth    required                        pam_google_authenticator.so|g' $path

# google-authenticator -t -D -W -r 3 -R 30

