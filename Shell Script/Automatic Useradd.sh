#!/bin/bash

USER="kartick"
USER_HDIR="home/$USER"s
USERID="2222"
PASSWD=""
LOG_FILE=/home/log.txt

useradd -u $USERID $USER -m -d $USER_HDIR -s /bin/bash

passwd $USER

chown $USER:$USER $USER_HDIR

cd $USER_HDIR

mkdir .ssh/

chmod 700 .ssh/

cd .ssh/

touch authorized_keys

cp /home/test.txt $USER_HDIR/.shh/authorized_keys

chmod 600 authorized_keys

chown $USER:$USER $USER_HDIR/.shh/authorized_keys

cd ..

chown $USER:$USER $USER_HDIR/.shh/

cd ..

cd ..

cd ..

usermod -aG sudo $USER

echo "Username: $USER" > $LOG_FILE
echo "User $USER created." > $LOG_FILE