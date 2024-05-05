#!/bin/bash

# 1. Création du namespace
# 2. Envoi de l'interface virtuelle
# 4. Configuration de l'interface virtuelle (dhclient)
# 5. Lancemenet du serveur lighttpd avec chroot


### 1 ###
rm /tmp/pid
unshare --user --net --uts --map-root-user bash ./echo_pid.sh &

while [ ! -f /tmp/pid ]; do
    sleep 1
done
pid=$(cat /tmp/pid)
echo "pid: $pid"

### 2 ###
ip link add vguest_1 link vmain type macvlan mode bridge
ip link set vguest_1 netns $pid

### 3 ###
nsenter -t $pid --net --user --uts --preserve-credential dhclient -4 -1 vguest_1


### 4 ###
nsenter -t $pid --net --user --uts --preserve-credential chroot containers/lighttpd_container/ bash -c 'lighttpd -f /etc/lighttpd/lighttpd.conf'
