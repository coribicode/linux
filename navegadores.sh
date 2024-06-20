####################################################
## NAVEGADORES CHROMIUM / FIREFOX / CHROME / EDGE ##
####################################################

## INSTALAÇÂO CHROMIUM
apt-get install chromium -y

## INSTALAÇÂO FIREFOX PT-BR
apt-get install firefox-esr-l10n-pt-br -y

## INSTALAÇÂO GOOGLE-CHROME-STABLE
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb -y

## INSTALAÇÃO MICROSOFT EDGE
apt-get install curl -y
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-stable.list'
sudo rm microsoft.gpg
sudo apt update
sudo apt install microsoft-edge-stable -y
