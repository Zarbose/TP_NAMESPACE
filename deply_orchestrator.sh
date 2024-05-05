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

# Démarage du serveur dhcp
/sbin/dhcpd -q-lf $PWD/tmp/leases_dhcp -pf $PWD/tmp/dhcpd.pid -cf $PWD/dhcpd.conf vhost 2>&1 /dev/null

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



nsenter -t $pid --net --user --uts --preserve-credential bash ./configure_interface.sh
