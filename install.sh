#!/bin/bash
# Criado por: Davi dos Santos Galúcio - 2024
# Verifica e instala pacote automaticamente
echo
echo "Este script verifica uma lista de pacotes instalados ou nao, e instala se possível!"
echo

for nome in nano sudo grub xrdp vim
  do
    pacote=$(dpkg --get-selections | grep ^"$nome" | grep -w install)
    sleep 2
    if [ -n "$pacote" ] ;
      then
      echo "Pacote [ $nome ]: OK!"
      echo "--------------------------------------------------------------------"
    else
      check_repo=$(apt-cache search $nome| grep ^"$nome ")
      if [ ! -n "$check_repo" ]
        then
        echo "Pacote [ $nome ]: Não Instalado!"
        sleep 2
        echo "Pacote [ $nome ]: ERROR - Não foi possível instalar porque não foi encontrado nos repositórios"
        echo "--------------------------------------------------------------------"
        exit ## >>>>>>> SAI DA INSTALAÇÃO SE HOUVER ERRO <<<<<<<<<<< ##
      fi
    echo "Pacote [ $nome ]: Não instalado!"
    sleep 2
    echo "Pacote [ $nome ]: Instalando pacote..."
    sleep 2
    #apt install -qq -y $pacote
    echo "Pacote [ $nome ]: OK!"
    echo "--------------------------------------------------------------------"
    fi
done
