#!/bin/bash
package_list="PACKAGE_NAME"
package_check_installed=$(sudo -u $USER WINEPREFIX_PATH winetricks list-installed | grep -w $package)
package_check=$(sudo -u $USER WINEPREFIX_PATH winetricks list-all | grep -w $package)
package_install=$(apt-get install -qq -y)

echo "--------------------------------------------------------------------"
for package in $package_list
do
  package_installed=$package_check_installed
  if [ -n "$package_installed" ] ;
  then
    echo "Pacote [ $package ]: OK!"
  else
    check_repo=$package_check
    if [ ! -n "$check_repo" ]
    then
      echo "Pacote [ $package ]: ERROR - Não foi possível instalar porque não foi encontrado nos repositórios"
      echo "--------------------------------------------------------------------"
      exit ## >>>>>>> SAI DA INSTALAÇÃO SE HOUVER ERRO <<<<<<<<<<< ##
    else
      export DEBIAN_FRONTEND=noninteractive
      $package_install $package 2>&2 /dev/null
      # Variável para controlar tentativas
      retry_count=0
      # Verifica se o pacote foi instalado, se não, tenta novamente uma vez
      while true; do
        check_package_installed=$package_check_installed
        if [ -n "$check_package_installed" ] ;
        then
          echo "Pacote [ $package ]: Instalado!"
          echo "--------------------------------------------------------------------"
          break
        else
          if [ $retry_count -eq 1 ]; then
            sleep 2
            echo "Houve erro na instalação, verifique os logs e tente novamnete"
            echo "--------------------------------------------------------------------"
            exit ## >>>>>>> SAI DA INSTALAÇÃO SE HOUVER ERRO <<<<<<<<<<< ##
          fi
          # Tentar novamente
          retry_count=$((retry_count + 1))
          sleep 2
          $package_install $package 2>&2 /dev/null
        fi
      done
    fi
  fi
done

for package in $package_list
do
  package_installed=$package_check_installed
  if [ -n "$package_installed" ] ;
  then
    echo "Pacote [ $package ]: OK!"
  else
    echo "..."
  if
done
