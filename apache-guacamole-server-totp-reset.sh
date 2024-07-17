#!/bin/bash

DBNAME=guac_db
DBUSER=guac_user
DBPASS=guac_password

DBCMD="mysql"

# Command to be used if credentials are defined in this script
#DBCMD="mysql --user=$DBUSER --password=$DBPASS"


if [ $# -ne 1 ]
then
        echo "Usage: $0 <username>"
else
        U=$1
        echo "Resetting OTP for user [$1]"
        echo "update 
    guacamole_user_attribute AS gua,
    guacamole_entity AS ge,
    guacamole_user AS gu
set 
    gua.attribute_value = 'false'
where
    (
        ge.type = 'USER' 
    AND
        ge.name = '$U'
    AND
        ge.entity_id = gu.entity_id  
    AND
        gu.user_id = gua.user_id
    AND
        attribute_name = 'guac-totp-key-confirmed'
    );" |$DBCMD $DBNAME

fi
