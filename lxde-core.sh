apt install -y lxde-core

apt install -y xrdp

sudo update-initramfs -u
## FIX BLACKSCREEN VM HYPER-V ##
cp /etc/default/grub /etc/default/grub.bkp
sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="quiet|GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nomodeset|g' /etc/default/grub
sudo update-grub
