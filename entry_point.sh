#!/bin/bash

#sudo /bin/su -c "echo \"address=/localhost/172.0.0.1\" >> /etc/dnsmasq.conf"
#sudo /bin/su -c "echo \"server=8.8.8.8\" >> /etc/dnsmasq.conf"
#sudo /bin/su -c "echo \"server=8.8.4.4\" >> /etc/dnsmasq.conf"

#sudo service dnsmasq restart

# SET THE DOCUMENT ROOT
if [ "$CI" = "true" ]; then
    sed -i -- "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www-ci\/public/ig" /etc/apache2/sites-enabled/000-default.conf
    sed -i 's/Directory \/var\/www\//Directory \/var\/www-ci\//g' /etc/apache2/apache2.conf
else
    sed -i -- "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/public/ig" /etc/apache2/sites-enabled/000-default.conf
fi
# Some apache tweaks
sed -i 's/AllowOverride\ None/AllowOverride\ All/g' /etc/apache2/apache2.conf

#allow remote mysql connections
sed -i 's/^bind-address.*$/bind-address = 0\.0\.0\.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo a2enmod rewrite

#start mariadb
service mysql start

#let mysql boot
sleep 2

mysql -uroot -proot <<-EOF
use mysql;
DELETE FROM mysql.user WHERE User='root';
INSERT INTO mysql.user (Host, User, Password) VALUES ('%', 'root', password('root'));
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH privileges;
exit
EOF

mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS fw2; CREATE DATABASE IF NOT EXISTS fw2testing;"

#start apache
service apache2 start

lastline=$(tail -1 /etc/dnsmasq.conf)
if [ "$lastline" == "server=8.8.4.4" ]; then
    echo "$(head -n -3 /etc/dnsmasq.conf)" > /etc/dnsmasq.conf
fi

sudo /bin/su -c "echo \"address=/localhost/127.0.0.1\" >> /etc/dnsmasq.conf"
sudo /bin/su -c "echo \"server=8.8.8.8\" >> /etc/dnsmasq.conf"
sudo /bin/su -c "echo \"server=8.8.4.4\" >> /etc/dnsmasq.conf"

sudo service dnsmasq restart

mkdir -vp /root/.vnc
# the default VNC password is 'hola'
x11vnc -storepasswd laravel /usr/sbin/vncpasswd

/usr/bin/supervisord

echo "$(sed '1i nameserver 127.0.0.1' /etc/resolv.conf)" > /etc/resolv.conf

if [ "$CI" = "true" ]; then
    echo "done booting"
else
    tail -f /dev/null
fi