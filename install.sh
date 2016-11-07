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
    echo -e "You have to chose one of the two following options : \033[31m--test\033[39m or \033[31m--prod\033[39m"
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
    echo "You chose "
    read distribution
done

# install mkpasswd
echo -e "      \033[33m#### Install server : install whois / mkpasswd ####\033[39m"
apt-get install -y whois
echo -e "      \033[33m#### Install server : end install whois / mkpasswd ####\033[39m"
if $debug; then
    echo "press a key to continue..."
    read trash
fi

if $mysql_pass; then
    echo "Saisie un mot de passe pour mysql (default root) "
    read password_mysql
    if [[ -z "$password_mysql" ]]
        then password_mysql="root"
    fi
    echo -e "mot de passe mysql choisi : \033[31m$password_mysql\033[39m"

    echo "appuyer sur entrée pour continuer"
    read trash
fi

tmp_password_ba_master=""
# mdp ba-master
while [[ -z "$tmp_password_ba_master" ]]
do
    echo "Saisie un mot de passe pour ba-master (obligatoire) "
    read tmp_password_ba_master
done
echo -e "\033[31mnotez le bien, c'est la dernière fois que vous le voyez\033[39m : "
echo -e "mot de passe ba-master choisi : \033[31m$tmp_password_ba_master\033[39m"

echo "appuyer sur entrée pour continuer"
read trash


password_ba_master=$(mkpasswd $tmp_password_ba_master)

## generation de la clée ssh du serveur
echo "-> génération de la clé ssh"
ssh-keygen -t rsa
echo -e "\033[31m#### IMPORTANT : voilà la clé ssh à copier dans github\033[39m"
echo " -==============================-"
cat ~/.ssh/id_rsa.pub
echo " -==============================-"
echo "-> une fois que vous aurez copier la clé dans github, appuyer sur entrée pour continuer"
read trash

echo ""

# set locale
echo -e "      \033[33m#### BA install : installation des locales ####\033[39m"
# locale-gen fr_FR.UTF-8
# update-locale LANG=fr_FR.UTF-8 LANGUAGE=fr_FR.UTF-8
cp ./sys/etc/locale.gen /etc/
# cp ./sys/etc/default/locale /etc/default
echo -e "\033[31m Attention : \033[39mconfiguration des locales :"
echo "-> au premier, appuyer sur entrée"
echo -e "-> au \033[31m2ème\033[39m écran choisir l'option : "
echo " > fr_FR.UTF-8 < "
read trash
dpkg-reconfigure locales
export LANGUAGE=fr_FR.UTF-8
export LANG=fr_FR.UTF-8
export LC_CTYPE=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8
echo -e "      \033[33m#### BA install : fin installation des locales ####\033[39m"

echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi


echo -e "      \033[33m#### BA install : installation server SMTP ####\033[39m"
apt-get install exim4
echo -e "\033[31m Attention : \033[39mconfiguration du SMTP, choisir la première option : "
echo " >  Distribution directe par SMTP (site Internet) < "
echo "puis toutes les options par default"
read trash
echo ""
dpkg-reconfigure exim4-config
# update-exim4.conf
# /etc/init.d/exim4 restart
echo -e "      \033[33m#### BA install : fin installation server SMTP ####\033[39m"
echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi

echo -e "      \033[32m#### BA install : fin initialisation ####\033[39m"
echo "appuyer sur entrée pour continuer, tout le reste est automatique"
read trash


# ajout utilisateur
# adduser ba-master
echo -e "      \033[33m#### BA install : creation de l'utilisateur apache ####\033[39m"
useradd ba-master --create-home --password $password_ba_master
echo -e "      \033[33m#### BA install : fin creation de l'utilisateur apache ####\033[39m"

echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi

# mise à jour dépots
echo -e "      \033[33m#### BA install : mise à jour des dépots ####\033[39m"
echo "deb http://packages.dotdeb.org $distribution_name all" >> /etc/apt/sources.list
echo "deb-src http://packages.dotdeb.org $distribution_name all" >> /etc/apt/sources.list
echo "deb http://packages.dotdeb.org $distribution_name-php56 all" >> /etc/apt/sources.list
echo "deb-src http://packages.dotdeb.org $distribution_name-php56 all" >> /etc/apt/sources.list
wget https://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg
apt-get update
apt-get dist-upgrade
echo -e "      \033[33m#### BA install : fin mise à jour des dépots ####\033[39m"

echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi

# install vim
echo -e "      \033[33m#### BA install : installation de vim ####\033[39m"
apt-get install -y vim
echo -e "      \033[33m#### BA install : fin installation de vim ####\033[39m"

echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi

# install acl
echo -e "      \033[33m#### BA install : installation des acl ####\033[39m"
apt-get install -y acl
echo -e "      \033[33m#### BA install : fin installation des acl ####\033[39m"

echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi

# install curl
echo -e "      \033[33m#### BA install : installation de curl ####\033[39m"
apt-get install -y curl
echo -e "      \033[33m#### BA install : fin installation de curl ####\033[39m"

echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi

# install mysql
echo -e "      \033[33m#### BA install : installation de mysql ####\033[39m"
if $mysql_pass; then
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $password_mysql"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $password_mysql"
fi
DEBIAN_FRONTEND="noninteractive" apt-get install -y mysql-server mysql-client libmysqlclient-dev mysql-common
echo -e "      \033[33m#### BA install : mysql: installation de la config  ####\033[39m"
cp ./sys/etc/mysql/my.cnf /etc/mysql/
echo -e "      \033[33m#### BA install : mysql: redemarrage du serveur  ####\033[39m"
service mysql restart
echo -e "      \033[33m#### BA install : fin installation de mysql ####\033[39m"
echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi

# install php5


echo -e "      \033[33m#### BA install : installation de php5 ####\033[39m"
apt-get install -y php5-fpm php5-intl
sed -i '/;date.timezone*/c\date.timezone = "Europe/Paris"' /etc/php5/fpm/php.ini
sed -i '/upload_max_filesize*/c\upload_max_filesize = "5M"' /etc/php5/fpm/php.ini
sed -i '/post_max_size*/c\post_max_size = "6M"' /etc/php5/fpm/php.ini
apt-get install -y php5-cli
sed -i '/;date.timezone*/c\date.timezone = "Europe/Paris"' /etc/php5/cli/php.ini
sed -i '/upload_max_filesize*/c\upload_max_filesize = "5M"' /etc/php5/cli/php.ini
sed -i '/post_max_size*/c\post_max_size = "6M"' /etc/php5/cli/php.ini
apt-get install -y php5-mysql php5-gd
echo -e "      \033[33m#### BA install : fin installation de php5 ####\033[39m"

echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi


echo -e "      \033[33m#### BA install : installation de composer ####\033[39m"
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
echo -e "      \033[33m#### BA install : fin installation de composer ####\033[39m"

echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi


echo -e "      \033[33m#### BA install : installation de nginx ####\033[39m"
apt-get install -y nginx
echo -e "      \033[33m#### BA install : nginx: installation de la config  ####\033[39m"
cp ./sys/etc/nginx/sites-available/default /etc/nginx/sites-available/
echo -e "      \033[33m#### BA install : nginx: redemarrage du serveur  ####\033[39m"
service nginx restart
echo -e "      \033[33m#### BA install : fin installation de nginx ####\033[39m"

echo ""
if $debug; then
    echo "appuyer sur entrée pour continuer ..."
    read trash
fi


if [ "$1" == "--test" ]; then
    echo -e "      \033[33m#### BA install : installation de node.js ####\033[39m"
    curl -sL https://deb.nodesource.com/setup_5.x | bash -
    apt-get install -y nodejs
    echo -e "      \033[33m#### BA install : fin installation de node.js ####\033[39m"

    echo ""
    if $debug; then
        echo "appuyer sur entrée pour continuer ..."
        read trash
    fi

    echo -e "      \033[33m#### BA install : installation de bower ####\033[39m"
    npm install -g bower
    echo -e "      \033[33m#### BA install : fin installation de bower ####\033[39m"

    echo ""
    if $debug; then
        echo "appuyer sur entrée pour continuer ..."
        read trash
    fi

    echo -e "      \033[33m#### BA install : installation de brunch ####\033[39m"
    npm install -g brunch
    echo -e "      \033[33m#### BA install : fin installation de brunch ####\033[39m"

    echo ""
    if $debug; then
        echo "appuyer sur entrée pour continuer ..."
        read trash
    fi

    echo -e "      \033[33m#### BA install : installation de java ####\033[39m"
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee /etc/apt/sources.list.d/webupd8team-java.list
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
    apt-get update
    apt-get install -y oracle-java7-installer
    echo -e "      \033[33m#### BA install : fin installation de java ####\033[39m"

    echo ""
    if $debug; then
        echo "appuyer sur entrée pour continuer ..."
        read trash
    fi

    echo -e "      \033[33m#### BA install : installation de jenkins ####\033[39m"
    wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add -
    sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
    apt-get update
    apt-get install -y jenkins

    echo -e "      \033[33m#### BA install : jenkins, installation de la config ####\033[39m"
    # installation de notre config :
    cp -R ./sys/etc/lib/jenkins/ /etc/lib/

    service jenkins restart
    echo -e "      \033[33m#### BA install : fin installation de jenkins ####\033[39m"

    echo ""
    if $debug; then
        echo "appuyer sur entrée pour continuer ..."
        read trash
    fi
fi

# ajout des utilisateus jenkins et www-data au groupe ba-master
echo -e "      \033[33m#### BA install : definition des droits ####\033[39m"
if [ "$1" == "--test" ]; then
    usermod -a -G ba-master jenkins
    usermod -a -G ba-master www-data

    mkdir /home/ba-master/sites

    chown jenkins /home/ba-master/sites
    chgrp ba-master /home/ba-master/sites
    chmod -R 775 /home/ba-master/sites
    chmod g+s /home/ba-master/sites
    setfacl -dm g::rwx /home/ba-master/sites

elif [ "$1" == "--prod" ]; then
    usermod -a -G ba-master www-data

    mkdir /home/ba-master/sites

    chown ba-master /home/ba-master/sites
    chgrp ba-master /home/ba-master/sites
    chmod -R 755 /home/ba-master/sites
fi
echo -e "      \033[33m#### BA install : fin definition des droits ####\033[39m"

echo "-= FIN DU SCRIPT =-"



