#!/bin/bash
## Création du namespace racine

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

number=$(cat /tmp/cpt)
number=$((number + 1))
sudo echo $number | sudo tee /tmp/cpt


# Création des interfcaes virtuelles entre le namespace racine et le premier namespace user
ip link add vhost_$number type veth peer name vmain_$number

# Configuration de l'interface virtuelle vhost du namespace racine
ip l set vhost_$number up
ip addr add 10.0.$number.2/24 dev vhost_$number

# Démarage du serveur dhcp
mkdir -p dhcpd_$number
touch dhcpd_$number/leases_dhcp
touch dhcpd_$number/dhcpd.pid
rm dhcpd_$number/leases_dhcp~ &> /dev/null

cat << EOF > dhcpd_$number/dhcpd.conf
default-lease-time 7000;
max-lease-time 7200;
ddns-update-style none;

subnet 10.0.$number.0 netmask 255.255.255.0 {
    option domain-name-servers 1.1.1.1;
    option domain-name "upjv.lan";
    option subnet-mask 255.255.255.0;
    option routers 10.0.$number.1;
    option broadcast-address 10.0.0.255;
    
    pool {
        range 10.0.$number.10 10.0.$number.100;
    }
}
EOF

chown root:root dhcpd_$number/dhcpd.conf
chown root:root -R dhcpd_$number

echo "##################"
/sbin/dhcpd -lf $PWD/dhcpd_$number/leases_dhcp -pf $PWD/dhcpd_$number/dhcpd.pid -cf $PWD/dhcpd_$number/dhcpd.conf vhost_$number
echo "##################"


rm /tmp/pid

# Lancemenet du namespace user
unshare --user --net --uts --map-root-user bash ./echo_pid.sh &

# Récupération du pid du namespace user
while [ ! -f /tmp/pid ]; do
    sleep 1
done
pid=$(cat /tmp/pid)
echo "pid: $pid"
echo "nsenter -t $pid --net --user --uts --preserve-credential bash"

# Envoyer l'interface virtuelle vmain dans le namespace user
ip link set vmain_$number netns $pid

echo "dhclient..."
nsenter -t $pid --net --user --uts --preserve-credential bash -c "dhclient -4 -1 vmain_$number"


## Création control groupe
echo "Control group -> orchestrator_$number"
moncgroup="orchestrator_$number"
mkdir /sys/fs/cgroup/$moncgroup
echo $pid > /sys/fs/cgroup/$moncgroup/cgroup.procs
echo +cpu > /sys/fs/cgroup/$moncgroup/cgroup.subtree_control

mkdir /tmp/$moncgroup/
echo "0" > /tmp/$moncgroup/cpt

for ((i=1; i<=$number; i++)); do
    echo 1000 $number"0000" > /sys/fs/cgroup/orchestrator_$i/cpu.max
done



# cat /proc/self/cgroup
# cat /sys/fs/cgroup/moncgroup/cgroup.procs
