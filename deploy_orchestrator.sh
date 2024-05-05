#!/bin/bash
## Création du namespace racine

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Création des interfcaes virtuelles entre le namespace racine et le premier namespace user
ip link add vhost type veth peer name vmain

# Configuration de l'interface virtuelle vhost du namespace racine
ip l set vhost up
ip addr add 10.0.0.2/24 dev vhost

# INTERFACE=$(ip route | grep '^default' | grep -Po '(?<=dev )(\S+)' | head -1)
# sysctl -w net.ipv4.ip_forward=1
# iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o $INTERFACE -j MASQUERADE

# Démarage du serveur dhcp
/sbin/dhcpd -q -lf $PWD/dhcpd/leases_dhcp -pf $PWD/dhcpd/dhcpd.pid -cf $PWD/dhcpd/dhcpd.conf vhost

rm /tmp/pid

# Lancemenet du namespace user
unshare --user --net --uts --map-root-user bash ./echo_pid.sh &

# Récupération du pid du namespace user
while [ ! -f /tmp/pid ]; do
    sleep 1
done
pid=$(cat /tmp/pid)
echo "pid: $pid"

# Envoyer l'interface virtuelle vmain dans le namespace user
ip link set vmain netns $pid

nsenter -t $pid --net --user --uts --preserve-credential bash dhclient -q -4 -1 vmain
