#!/bin/bash

## Préparation de l'environnement

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

if ! dpkg -s isc-dhcp-server >/dev/null 2>&1; then
    echo "isc-dhcp-server is not installed"
    read -p "Do you want to install isc-dhcp-server? (y/n): " choice
    if [[ $choice == "y" ]]; then
        apt-get install isc-dhcp-server
    else
        exit 1
    fi
fi

pkill dhcpd

mkdir -p tmp
touch tmp/leases_dhcp
touch tmp/dhcpd.pid

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
}' > dhcpd.conf

chown root:root dhcpd.conf
chown root:root -R tmp



systemctl stop apparmor.service
cp /etc/apparmor.d/usr.sbin.dhcpd /etc/apparmor.d/disable/
systemctl restart apparmor.service
sudo aa-remove-unknown
systemctl stop apparmor.service
