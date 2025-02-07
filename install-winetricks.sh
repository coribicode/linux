#!/bin/bash
package_list='PACKAGE_NAME'
echo "--------------------------------------------------------------------"
for package in $package_list
do
  package_installed=$(sudo -u $USER WINEPREFIX_PATH winetricks list-installed | grep -w $package)
  if [ -n "$package_installed" ] ;
  then
    echo "Pacote [ $package ]: OK!"
    echo "--------------------------------------------------------------------"
  else
    check_repo=$(sudo -u $USER WINEPREFIX_PATH winetricks list-all | grep -w $package)
    if [ ! -n "$check_repo" ]
    then
      echo "Pacote [ $package ]: ERROR - Não foi possível instalar porque não foi encontrado nos repositórios"
      echo "--------------------------------------------------------------------"
      exit ## >>>>>>> SAI DA INSTALAÇÃO SE HOUVER ERRO <<<<<<<<<<< ##
    else
      echo "Pacote [ $package ]: Não instalado!"
      sleep 2
      echo "Pacote [ $package ]: Instalando pacote..."
      sleep 2
      # export DEBIAN_FRONTEND=noninteractive
      # apt install -qq -y $package > /dev/null
      sudo -u $USER WINEPREFIX_PATH winetricks -q $package | grep -w installed 2> /dev/null
      # Variável para controlar tentativas
      retry_count=0
      # Verifica se o pacote foi instalado, se não, tenta novamente uma vez
      while true; do
        check_package_installed=$(sudo -u $USER WINEPREFIX_PATH winetricks list-installed | grep -w $package)
        if [ -n "$check_package_installed" ] ;
        then
          echo "Pacote [ $package ]: Instalado!"
          echo "--------------------------------------------------------------------"
          break
        else
          if [ $retry_count -eq 1 ]; then
            echo "Pacote [ $package ]: Não Instalado!"
            sleep 2
            echo "Houve erro na instalação, verifique os logs e tente novamnete"
            echo "--------------------------------------------------------------------"
            exit ## >>>>>>> SAI DA INSTALAÇÃO SE HOUVER ERRO <<<<<<<<<<< ##
          fi
          # Tentar novamente
          echo "Pacote [ $package ]: Tentando instalar novamente..."
          retry_count=$((retry_count + 1))
          sleep 2
          sudo -u $USER WINEPREFIX_PATH winetricks -q $package | grep -w installed 2> /dev/null
        fi
      done
    fi
  fi
done
