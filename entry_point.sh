#!/bin/bash

#sudo /bin/su -c "echo \"address=/dev/172.0.0.1\" >> /etc/dnsmasq.conf"
#sudo /bin/su -c "echo \"server=8.8.8.8\" >> /etc/dnsmasq.conf"
#sudo /bin/su -c "echo \"server=8.8.4.4\" >> /etc/dnsmasq.conf"

#sudo service dnsmasq restart

# SET THE DOCUMENT ROOT
if [ "$CI_ENV" = true ] ; then
    sed -i -- "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www-ci\/public/ig" /etc/apache2/sites-enabled/000-default.conf
else
    sed -i -- "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/public/ig" /etc/apache2/sites-enabled/000-default.conf
fi
# Some apache tweaks
sed -i 's/AllowOverride\ None/AllowOverride\ All/g' /etc/apache2/apache2.conf

sudo a2enmod rewrite

#start mariadb
service mysql start

mysql -u root -proot <<-EOF
use mysql;
DELETE FROM mysql.user WHERE User='root';
INSERT INTO mysql.user (Host, User, Password) VALUES ('%', 'root', password('root'));
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH privileges;
exit
EOF

mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS fw2; CREATE DATABASE IF NOT EXISTS fw2testing;"

#start apache
service apache2 start

lastline=$(tail -1 /etc/dnsmasq.conf)
if [ "$lastline" == "server=8.8.4.4" ]; then
    echo "$(head -n -3 /etc/dnsmasq.conf)" > /etc/dnsmasq.conf
fi

sudo /bin/su -c "echo \"address=/dev/127.0.0.1\" >> /etc/dnsmasq.conf"
sudo /bin/su -c "echo \"server=8.8.8.8\" >> /etc/dnsmasq.conf"
sudo /bin/su -c "echo \"server=8.8.4.4\" >> /etc/dnsmasq.conf"

sudo service dnsmasq restart

mkdir -vp /root/.vnc
# the default VNC password is 'hola'
x11vnc -storepasswd laravel /usr/sbin/vncpasswd

/usr/bin/supervisord

tail -f /dev/null