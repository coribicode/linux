#!/bin/bash
# Criado por: Davi dos Santos Galúcio - 2024
# Verifica e instala pacote automaticamente
echo
echo "Este script verifica uma lista de pacotes instalados ou nao, e instala se possível!"
echo

package_list="nano aptitude notepadqq"

for package in $package_list
  do
    package_installed=$(dpkg --get-selections | grep ^"$package" | grep -w install)
    sleep 2
    if [ -n "$package_installed" ] ;
      then
      echo "Pacote [ $package ]: OK!"
      echo "--------------------------------------------------------------------"
    else
      check_repo=$(apt-cache search $package| grep ^"$package ")
      if [ ! -n "$check_repo" ]
        then
        echo "Pacote [ $package ]: Não Instalado!"
        sleep 2
        echo "Pacote [ $package ]: ERROR - Não foi possível instalar porque não foi encontrado nos repositórios"
        echo "--------------------------------------------------------------------"
        exit ## >>>>>>> SAI DA INSTALAÇÃO SE HOUVER ERRO <<<<<<<<<<< ##
      fi
    echo "Pacote [ $package ]: Não instalado!"
    sleep 2
    echo "Pacote [ $package ]: Instalando pacote..."
    echo
    sleep 2
    apt install -qq -y $package 2>/dev/null | grep "E:"
    check_package_installed=$(dpkg --get-selections | grep ^"$package" | grep -w install)
    sleep 2
    if [ -n "$check_package_installed" ] ;
      then
      echo
      echo "Pacote [ $package ]: Instalado!"
      echo "--------------------------------------------------------------------"
    else
      echo "Pacote [ $package ]: Não Instalado!"
      sleep 2
      echo "Houve erro na instalação, verifique os logs e tente novamnete"
      echo "--------------------------------------------------------------------"
      exit ## >>>>>>> SAI DA INSTALAÇÃO SE HOUVER ERRO <<<<<<<<<<< ##
    fi
  fi
done
