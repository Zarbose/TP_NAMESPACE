#!/bin/bash

## Création du namespace racine

# Création des interfcaes virtuelles entre le namespace racine et le premier namespace user
ip link add vhost type veth peer name vmain

# Configuration de l'interface virtuelle vhost du namespace racine
ip l set vhost up
ip addr add 10.0.0.2/24 dev vhost

# Démarage du serveur dhcp
/sbin/dhcpd -lf $PWD/tmp/leases_dhcp -pf $PWD/tmp/dhcpd.pid -cf $PWD/dhcpd.conf vhost

# Lancemenet du namespace user
./user.sh &

# Récupération du pid du namespace user
user_pid=$!

# Envoyer l'interface virtuelle vmain dans le namespace user
ip link set vmain netns $user_pid