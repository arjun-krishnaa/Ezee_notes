# Linux user Creation 

## Creating user 

Login into ec2 server and switch to root user

Create user, home directory and default shell

```
useradd -u 1234 appuser -m -d /home/appuser/ -s /bin/bash/
```
Give password to the user
```
passwd appuser
```

## Create and place key

Create one public and private in puttygen with password.

Make directory
```
mkdir home/appuser/.ssh/
```
Create **authorized_keys** file

```
vi home/appuser/.ssh/authorized_keys
```
And paste the generated public key in that file.

### Give permission and change ownership to that file "authorized_keys"

```
chmod 600 home/appuser/.ssh/authorized_keys
chown - R appuser:appuser home/appuser/.ssh/authorized_keys
```

### Give permission and change ownership to ".ssh" directory
```
chmod 700 home/appuser/.ssh
chown -R appuser:appuser home/appuser/.ssh
```

### Give permission and change ownership to "appuser" directory

```
chmod 755 home/appuser
chown -R appuser:appuser home/appuser
```
### To read ssh securely use "restorecon" to prevent permission loss

```
restorecon -Rv /home/ec2-user/.ssh
```
### Freeze the folder "home/ec2-user/.ssh"
```
chown root:root /home/ec2-user/.ssh/authorized_keys
chmod 600 /home/ec2-user/.ssh/authorized_keys
chattr +i /home/ec2-user/.ssh/authorized_keys
```
### To unfreeze the folder
```
chattr -i /home/ec2-user/.ssh/authorized_keys
```
whenever you want to uses these command to unfreeze.

## Give permissions to the user
Create one file in "/etc/sudoers.d/appuser"
```
vi etc/sudoers.d/appuser
```
Paste the permissions in that file

```
Cmnd_Alias SERVICE_MGMT = \
    /bin/systemctl start nginx, \
    /bin/systemctl stop nginx, \
    /bin/systemctl status nginx, \
    /bin/systemctl restart nginx, \
    /bin/systemctl start php-fpm, \
    /bin/systemctl stop php-fpm, \
    /bin/systemctl status php-fpm, \
    /bin/systemctl restart php-fpm, \
    /bin/systemctl start amazon-ssm-agent, \
    /bin/systemctl stop amazon-ssm-agent, \
    /bin/systemctl status amazon-ssm-agent, \
    /bin/systemctl restart amazon-ssm-agent, \
    /bin/systemctl start redis, \
    /bin/systemctl stop redis, \
    /bin/systemctl status redis, \
    /bin/systemctl restart redis, \
    /bin/systemctl start redis-server, \
    /bin/systemctl stop redis-server, \
    /bin/systemctl status redis-server, \
    /bin/systemctl restart redis-server

Cmnd_Alias READ_ONLY = \
    /bin/df, \
    /bin/free, \
    /usr/bin/free, \
    /bin/ps, \
    /usr/bin/ps, \
    /usr/bin/top, \
    /bin/cat, \
    /usr/bin/tail, \
    /bin/ls, \
    /bin/du

Cmnd_Alias NGINX_LOG_OPS = \
    /bin/cp /var/log/nginx/* /var/log/nginx/*, \
    /bin/mv /var/log/nginx/* /var/log/nginx/*, \
    /bin/ls /var/log/nginx, \
    /bin/ls /var/log/nginx/*

appuser ALL=(root) NOPASSWD: SERVICE_MGMT, READ_ONLY, NGINX_LOG_OPS


appuser ALL = !/bin/rm, !/bin/rmdir, !/bin/chmod, !/bin/chown, \ !/usr/bin/apt, !/usr/bin/yum, !/usr/bin/dnf, \ !/bin/vim, !/bin/nano, !/bin/sed, !/usr/bin/crontab

```
Then give permission to "appuser" file

```
chmod 600 etc/sudoers.d/appuser
```
Reload **"sshd"** one time
```
systemctl reload sshd
```


### Give permission to specific folder

Set a acccess control list for "var/log/nginx" and /home/ec2-user 

Permissions for "/var/log/nginx" to excecute create, delete, copy and move commands
```
setfacl -m u:produser:rwx /var/log/nginx/ 
```
Permission for "/home/ec2-user/" to create and move file from or in to the server from pc
```
setfacl -m u:produser:rwx /home/ec2-user/
```
### Remove edit access to users in "./ssh" directory

Edit the "sudo" file to remove access or read only access
```
visudo
```
Paste this script to remove access

```
produser ALL=(ALL) ALL, \
    !/bin/nano /home/produser/.ssh/authorized_keys, \
    !/bin/vi /home/produser/.ssh/authorized_keys, \
    !/usr/bin/vim /home/produser/.ssh/authorized_keys, \
    !/bin/sed /home/produser/.ssh/authorized_keys, \
    !/bin/chmod /home/produser/.ssh/authorized_keys, \
    !/bin/chown /home/produser/.ssh/authorized_keys

appuser ALL=(ALL) ALL, \
    !/bin/nano /home/appuser/.ssh/authorized_keys, \
    !/bin/vi /home/appuser/.ssh/authorized_keys, \
    !/usr/bin/vim /home/appuser/.ssh/authorized_keys, \
    !/bin/sed /home/appuser/.ssh/authorized_keys, \
    !/bin/chmod /home/appuser/.ssh/authorized_keys, \
    !/bin/chown /home/appuser/.ssh/authorized_keys

```
Reload "ssh" again
```
systemctl reload sshd
```
#### Install nginx - for demo purpose

```
yum install nginx -y
```
Start nginx

```
systemctl start nginx
```

### Login into server as a "appuser"

Use the new created ```.ppk``` to login into server as a ```appuser ```

Now ```appuser``` can start, stop, restart and see status of nginx

```
systemctl status nginx
systemctl stop nginx
systemctl start nginx
systemctl start nginx
```
Edit files in ```/var/log/nginx``` and ```/home/ec2-user```


