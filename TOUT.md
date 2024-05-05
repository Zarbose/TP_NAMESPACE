##### ÉTAPE 1 #####

pkill dhcpd

### Côté namespace racine (privilèges root)
# Créer et configurer une interface veth

ip link add vhost type veth peer name vmain

# Faites le nécessaire pour lancer dhcpd sur l’interface veth

sudo apt install isc-dhcp-server

mkdir tmp
sudo touch tmp/leases_dhcp
sudo touch tmp/dhcpd.pid

chown root:root dhcpd.conf
chown root:root -R tmp

systemctl stop apparmor.service
cp /etc/apparmor.d/usr.sbin.dhcpd /etc/apparmor.d/disable/
systemctl restart apparmor.service
sudo aa-remove-unknown
systemctl stop apparmor.service

ip l set vhost up
ip addr add 10.0.0.2/24 dev vhost

/sbin/dhcpd -lf $PWD/tmp/leases_dhcp -pf $PWD/tmp/dhcpd.pid -cf $PWD/dhcpd.conf vhost

# Placer l’interface appairée dans le namespace user
sudo unshare --user --net --uts --map-root-user bash
echo $$
ip link set vmain netns $PID


### Coté namespace (user non privilégié)
# Pas de sudo
ip addr add 10.0.0.10/24 dev vmain
ip l set vmain up


##### ÉTAPE 2 #####
<!-- ip l set vguest1 nets PID
nsenter -t PID --net --user --uts --preserve-credential bash -->


# Creer l'interface vguest_n
ip link add vguest_1 link vmain type macvlan mode bridge
ip link set vguest_1 netns <PID>

# DANS CHROOT
<!-- ip l set vguest_1 up -->
# Il faut adapter le cript /usr/sbin/dhclient-script pour l'utiliser sans root
dhclient -4 -1 -v vguest_1


