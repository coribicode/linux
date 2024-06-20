sudo apt install -y cpu-checker
sudo kvm-ok

sudo apt-get install -y qemu-kvm qemu-user-static qemu-utils bridge-utils dnsmasq virt-manager libvirt-clients libvirt-daemon-system libguestfs-tools libosinfo-bin ovmf
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo usermod -a -G libvirt $USER

sudo sed -i 's|#uri_default = "qemu:///system"|uri_default = "qemu:///system"|g' /etc/libvirt/libvirt.conf

virsh --connect=qemu:///system net-autostart default

sudo modprobe vhost_net



cat <<"EOF">> /etc/modules
vhost_net
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd

## options vfio-pci ids=XXXX:XXXX, YYYY:YYYY
## Para adicionar o ID do PCI para passtrough, use o comando "lspci -nn" para listar os dispositivos, as ids estão entre cochetes "[]".
## Copie e cole em "options vfio-pci ids=XXXX:XXXX que são a numeração coletadas acima, separadas por virgula cada dispositivo.
## Para listar os dispositivos adicionados ao IOMMU, digite o comando: "journalctl -b 0 | grep -i iommu"

EOF

# Check os drivers em uso do Kernel com o comando: "lspci -vnn"
# Depois crie o arquivo para desativar os drvers da inicialização do kernel

# cat <<"EOF">> /etc/modprobe.d/vfio.conf
# softdep nouveau pre: vfio-pci
# softdep snd_hda_intel pre: vfio-pci
# options vfio-pci ids=XXXX:XXXX,YYYY:YYYY
# EOF

sudo update-initramfs -u

# Depois, pré-check os drivers em uso do Kernel com o comando: "lspci -vnn" e verifique se "vfio-pci" aparece em uso para os dispostivos selecionados.
# Fonte: https://gist.github.com/nephest/c2d2c31417be545c3c6eef2cec0e796e


sudo sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="quiet"|GRUB_CMDLINE_LINUX_DEFAULT="quiet preempt=voluntary iommu=pt amd_iommu=on intel_iommu=on"|g' /etc/default/grub
# Fonte: https://github.com/small-hack/smol-gpu-passthrough

sudo grub-mkconfig -o /boot/grub/grub.cfg

sudo update-initramfs -c -k $(uname -r)

###################################################################################
## Teste IOMMU support pelo Windows via powershell
## (Get-VMHost).IovSupport; (Get-VMHost).IovSupportReasons
## get-vmswitch | fl *iov*
## Get-VM | Format-List -Property *

## https://www.youtube.com/watch?v=g--fe8_kEcw

## cat <<'EOF'>> /etc/modprobe.d/vfio.conf
## options vfio-pci ids=10de:1f99,10de:10fa
## softdep nvidia pre: vfio-pci
## EOF

## lspci -k | grep -E "vfio-pci|NVIDIA"

## wget -P /opt/ https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
