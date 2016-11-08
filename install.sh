#!/bin/bash

# only root can use it
if [ "$UID" -ne "0" ]
then
   echo "Please connect with root user"
   exit 1
fi

debug=false
mysql_pass=true

# test de l'environnement
if [ "$1" == "--test" ]; then
    echo -e "\033[31mInstall TEST server \033[39m"
elif [ "$1" == "--prod" ]; then
    echo -e "\033[31mInstall PROD server: \033[39m"
else
    echo -e "You have to choose one of the two following options : \033[31m--test\033[39m or \033[31m--prod\033[39m"
    exit 1
fi

echo -e "      \033[32m#### Install server : init ####\033[39m"

distribution=`cat /etc/issue | sed "s/Debian GNU\/Linux //" | sed "s/ \\\\n \\\\l//"`
distribution_name=error

if [ "${distribution:0:1}" == "7" ]; then
    distribution_name=wheezy
fi

if [ "${distribution:0:1}" == "8" ]; then
    distribution_name=jessie
fi

if [ "$distribution_name" == "error" ]; then
    echo -e "\033[31mErreur: unknown Unix/Debian version \033[39m"
    exit
else
    echo -e "\033[31mInstalling $distribution_name \033[39m"
fi

while [[ -z "$distribution" ]]
do
    echo "You choose "
    read distribution
done

# install mkpasswd (package of whois)
echo -e "      \033[33m#### Install server : install whois / mkpasswd ####\033[39m"
apt-get install -y whois
echo -e "      \033[33m#### Install server : end install whois / mkpasswd ####\033[39m"
if $debug; then
    echo "press a key to continue..."
fi

if $mysql_pass; then
    password_mysql = $(mkpasswd -l 10 -d 3 -c 2 -C 2 -s 2)
    echo -e "The mysql password choosen is : \033[31m$password_mysql\033[39m"
    echo "press a key to continue..."
fi

tmp_password_jmp_master=""
while [[ -z "$tmp_password_jmp_master" ]]
do
    tmp_password_jm_master = $(mkpasswd -l 10 -d 3 -c 2 -C 2 -s 2)
done
echo -e "Password for jm-master generated : \033[31m$tmp_password_jmp_master\033[39m"
echo "press a key to continue..."
password_jm_master=$(mkpasswd $tmp_password_jm_master)

echo "-> generating ssh keys"
ssh-keygen -t rsa
echo -e "\033[31m#### IMPORTANT : here is your ssh public key:\033[39m"
echo " -==============================-"
cat ~/.ssh/id_rsa.pub
echo " -==============================-"
echo "press a key to continue..."
read trash

echo -e "\033[33m#### Install server : install locales ####\033[39m"
cp ./sys/etc/locale.gen /etc/
echo "First press enter, then choose fr_FR.UTF-8"
read trash
dpkg-reconfigure locales
export LANGUAGE=fr_FR.UTF-8
export LANG=fr_FR.UTF-8
export LC_CTYPE=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8
echo -e "\033[33m#### Install server : end install locales ####\033[39m"
if $debug; then
    echo "press a key to continue..."
    read trash
fi

echo -e "\033[33m#### Install server : SMTP ####\033[39m"
apt-get install exim4
echo -e "\033[31m Warning : \033[39mChoose :"
echo " >  Distribution directe par SMTP (site Internet) < "
echo "and all defaults actions"
read trash
echo ""
dpkg-reconfigure exim4-config

echo -e "\033[33m#### Install server : end SMTP ####\033[39m"
echo ""
if $debug; then
    echo "press a key to continue..."
    read trash
fi
echo -e "\033[32m#### Install server : end init ####\033[39m"
echo "press a key to continue..."
read trash

# adduser jmp-master
echo -e "\033[33m#### Install server : add apache user ####\033[39m"
useradd jmp-master --create-home --password $password_jmp_master
echo -e "\033[33m#### Install server : end add apache user ####\033[39m"
echo ""
if $debug; then
    echo "press a key to continue..."
    read trash
fi

# upgrades
echo -e "\033[33m#### Install server : upgrades ####\033[39m"
echo "deb http://packages.dotdeb.org $distribution_name all" >> /etc/apt/sources.list
echo "deb-src http://packages.dotdeb.org $distribution_name all" >> /etc/apt/sources.list
echo "deb http://packages.dotdeb.org $distribution_name-php56 all" >> /etc/apt/sources.list
echo "deb-src http://packages.dotdeb.org $distribution_name-php56 all" >> /etc/apt/sources.list
wget https://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg
apt-get update
apt-get dist-upgrade
echo -e "\033[33m#### Install server : end upgrades ####\033[39m"
echo ""
if $debug; then
    echo "press a key to continue..."
    read trash
fi

echo -e "      \033[33m#### Install server : install vim ####\033[39m"
apt-get install -y vim
echo -e "      \033[33m#### Install server : install acl ####\033[39m"
apt-get install -y acl
echo -e "      \033[33m#### Install server : install curl ####\033[39m"
apt-get install -y curl
echo -e "      \033[33m#### Install server : install mysql ####\033[39m"
if $mysql_pass; then
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $password_mysql"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $password_mysql"
fi
DEBIAN_FRONTEND="noninteractive" apt-get install -y mysql-server mysql-client libmysqlclient-dev mysql-common
cp ./sys/etc/mysql/my.cnf /etc/mysql/
service mysql restart
echo -e "      \033[33m#### Install server : install php ####\033[39m"
apt-get install -y php5-fpm php5-intl
sed -i '/;date.timezone*/c\date.timezone = "Europe/Paris"' /etc/php5/fpm/php.ini
sed -i '/upload_max_filesize*/c\upload_max_filesize = "5M"' /etc/php5/fpm/php.ini
sed -i '/post_max_size*/c\post_max_size = "6M"' /etc/php5/fpm/php.ini
apt-get install -y php5-cli
sed -i '/;date.timezone*/c\date.timezone = "Europe/Paris"' /etc/php5/cli/php.ini
sed -i '/upload_max_filesize*/c\upload_max_filesize = "5M"' /etc/php5/cli/php.ini
sed -i '/post_max_size*/c\post_max_size = "6M"' /etc/php5/cli/php.ini
apt-get install -y php5-mysql php5-gd
echo -e "      \033[33m#### Install server : install composer ####\033[39m"
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
echo -e "      \033[33m#### Install server : install nginx ####\033[39m"
apt-get install -y nginx
echo -e "      \033[33m#### Install server : config vhosts composer ####\033[39m"
cp ./sys/etc/nginx/sites-available/default /etc/nginx/sites-available/
service nginx restart
echo ""
if $debug; then
    echo "press a key to continue..."
    read trash
fi

if [ "$1" == "--test" ]; then
    echo -e "      \033[33m#### Install server : install node.js ####\033[39m"
    curl -sL https://deb.nodesource.com/setup_5.x | bash -
    apt-get install -y nodejs
    echo -e "      \033[33m#### Install server : install bower ####\033[39m"
    npm install -g bower
    echo -e "      \033[33m#### Install server : install brunch ####\033[39m"
    npm install -g brunch
    echo -e "      \033[33m#### Install server : install java ####\033[39m"
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee /etc/apt/sources.list.d/webupd8team-java.list
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
    apt-get update
    apt-get install -y oracle-java7-installer
    echo -e "      \033[33m#### Install server : install jenkins ####\033[39m"
    wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add -
    sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
    apt-get update
    apt-get install -y jenkins
    echo -e "      \033[33m#### Install server : config jenkins ####\033[39m"
    cp -R ./sys/etc/lib/jenkins/ /etc/lib/
    service jenkins restart
    echo ""
    if $debug; then
        echo "press a key to continue..."
        read trash
    fi
fi

echo -e "      \033[33m#### Install server : users rights ####\033[39m"
if [ "$1" == "--test" ]; then
    usermod -a -G jmp-master jenkins
    usermod -a -G jmp-master www-data
    mkdir /home/jmp-master/sites
    chown jenkins /home/jmp-master/sites
    chgrp jmp-master /home/jmp-master/sites
    chmod -R 775 /home/jmp-master/sites
    chmod g+s /home/jmp-master/sites
    setfacl -dm g::rwx /home/jmp-master/sites
elif [ "$1" == "--prod" ]; then
    usermod -a -G jmp-master www-data
    mkdir /home/jmp-master/sites
    chown jmp-master /home/jmp-master/sites
    chgrp jmp-master /home/jmp-master/sites
    chmod -R 755 /home/jmp-master/sites
fi
echo "-= THE END OF THE END =-"
