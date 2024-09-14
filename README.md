# ServerScripts

Script for new server including
- Install zip unzip
- Set bashrc
- Set Swap
- Set hostname
- Set timezone
- Install webserver
  - Openlitespeed with PHP
  - Nginx with PHP
  - Apache2 with PHP
- Install MariaDB
- Install Wordpress
- Install wp-cli
- and many more!!

# Installation
1. run command
```bash
wget https://raw.githubusercontent.com/luozongbao/ServerScripts/main/actions.sh
wget https://raw.githubusercontent.com/luozongbao/ServerScripts/main/wpbackup.sh
wget https://raw.githubusercontent.com/luozongbao/ServerScripts/main/wpclean.sh
wget https://raw.githubusercontent.com/luozongbao/ServerScripts/main/wprestore.sh
```
2. make the file executable
```bash
chmod +x actions.sh
```
3. excute with sudo privileges
```bash
sudo ./actions.sh
```
