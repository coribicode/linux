#!/bin/bash
# Criado por: Davi dos Santos Galúcio - 2024
# Verifica e instala pacote automaticamente
echo
echo "Este script verifica uma lista de pacotes instalados ou nao, e instala se possível!"
echo
package_list="nano sudo git build-essntials"
for package in $package_list
  do
    pacote=$(dpkg --get-selections | grep ^"$package" | grep -w install)
    sleep 2
    if [ -n "$pacote" ] ;
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
    sleep 2
    apt install -qq -y $package
    echo "Pacote [ $package ]: OK!"
    echo "--------------------------------------------------------------------"
    fi
done
