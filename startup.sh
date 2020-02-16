#!/bin/bash

service apache2 start
sed -i 's/^bind-address.*$/bind-address = 0\.0\.0\.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf
service mysql start

#let mysql boot
sleep 2

mysql -uroot -proot <<-EOF
use mysql;
DELETE FROM mysql.user WHERE User='root';
INSERT INTO mysql.user (Host, User, authentication_string) VALUES ('%', 'root', password('root'));
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH privileges;
exit
EOF

mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS fw2; CREATE DATABASE IF NOT EXISTS fw2testing;"

lastline=$(tail -1 /etc/dnsmasq.conf)
if [[ "$lastline" == "server=8.8.4.4" ]]; then
    echo "$(head -n -3 /etc/dnsmasq.conf)" > /etc/dnsmasq.conf
fi

sudo /bin/su -c "echo \"address=/localhost/127.0.0.1\" >> /etc/dnsmasq.conf"
sudo /bin/su -c "echo \"server=8.8.8.8\" >> /etc/dnsmasq.conf"
sudo /bin/su -c "echo \"server=8.8.4.4\" >> /etc/dnsmasq.conf"

sudo service dnsmasq restart

echo "$(sed '1i nameserver 127.0.0.1' /etc/resolv.conf)" > /etc/resolv.conf
