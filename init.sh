#!/bin/bash

## Préparation de l'environnement

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

if ! command -v dhcpd >/dev/null 2>&1; then
    echo "dhcpd is not installed"
    read -p "Do you want to install dhcpd? (y/n): " choice
    if [[ $choice == "y" ]]; then
        apt-get install dhcpd
    else
        exit 1
    fi
fi

pkill dhcpd

mkdir -p dhcpd
touch dhcpd/leases_dhcp
touch dhcpd/dhcpd.pid
rm dhcpd/leases_dhcp~ 

echo 'default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;

subnet 10.0.0.0 netmask 255.255.255.0 {
    
    option domain-name-servers 1.1.1.1;
    option domain-name "upjv.lan";
    option subnet-mask 255.255.255.0;
    option routers 10.0.0.1;
    option broadcast-address 10.0.0.255;
    
    pool {
        range 10.0.0.10 10.0.0.100;
    }
}' > dhcpd/dhcpd.conf

chown root:root dhcpd/dhcpd.conf
chown root:root -R dhcpd

echo "-------------- Les instruction pour désactivée apparmor sont les suivantes --------------"
echo "systemctl stop apparmor.service"
echo "cp /etc/apparmor.d/usr.sbin.dhcpd /etc/apparmor.d/disable/"
echo "systemctl restart apparmor.service"
echo "sudo aa-remove-unknown"
echo "systemctl stop apparmor.service"
echo
echo "ATTENTION: Il ne faut le faire qu'une seule fois !!!!!"

chmod +x deploy_containers.sh
chmod +x deploy_orchestrator.sh
chmod +x echo_pid.sh

cd containers
# chmod u+x build_lighttpd.sh
# sudo ./build_lighttpd.sh


chmod u+x build_bash.sh
sudo ./build_bash.sh

