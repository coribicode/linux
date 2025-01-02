#!/bin/sh
clear
pergunta(){
 while true; do
  echo
  echo "======== Bem-vindo a Instalação do SAMBA4 ========="
  echo
  read -p "Informe o nome para este SERVIDOR [ex: SRVLDAP001 ]: " servername
  read -p "Informe o nome de DOMINIO [ ex: EMPRESA.NETLAN ]: " dominio
  stty -echo
  echo "Informe a senha do administrator@$dominio"
  read -p "Senha: " senha1
  echo
  read -p "Confirme a senha: " senha2
  stty echo
  echo
  if [ "$senha1" = "$senha2" ]; then
   valida
  else
   echo "------------------------------"
   echo "As senhas não coincidem!"
   verifica
  fi
 done
}

verifica(){
 echo
 echo -n "Deseja tentar novamente? (s/n): "
 read resposta
 case $resposta in
  s|S) pergunta ;;
  n|N) exit 0 ;;
  *) echo "Opção Inválida."
     verifica;;
 esac
}

valida(){
 echo
 echo "-----------------------------------------------------"
 echo "Dominio: $dominio"
 echo "Credênciais: administrator@$dominio"
 echo
 echo "Nome do Servidor: $servername.$dominio"
 echo "IP: $(hostname -I | cut -d ' ' -f 1)"
 echo "-----------------------------------------------------"
 echo -n "Validar informações acima e INSTALAR o SAMBA4? (s/n): "
 read resp
 case $resp in
  s|S) instalar ;;
  n|N) sair ;;
  *) echo "Opção Inválida."
     valida;;
 esac
}

sair(){
 echo
 echo -n "Sair da instalação? (s/n): "
 read resp1
 case $resp1 in
  s|S) exit 0 ;;
  n|N) pergunta ;;
  *) echo "Opção Inválida."
     sair;;
 esac
}

instalar(){
 echo
 sleep 3
 echo "[INSTALAÇÃO]: Instalando o SAMBA4 agora ... "
 sleep 5
 echo "..."
 echo
 exit 0
}
pergunta
