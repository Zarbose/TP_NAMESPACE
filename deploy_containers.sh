#!/bin/bash -x

# 1. Création du namespace
# 2. Envoi de l'interface virtuelle
# 4. Configuration de l'interface virtuelle (dhclient)
# 5. Lancemenet du serveur lighttpd avec chroot

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

read -p "Quel est le numéro de namespace ? : " num_orchestrator

number=$(cat /tmp/orchestrator_$num_orchestrator/cpt)
number=$((number + 1))
echo $number | tee /tmp/orchestrator_$num_orchestrator/cpt

### 1 ###
rm /tmp/pid
unshare --user --net --uts --map-root-user bash ./echo_pid.sh &

while [ ! -f /tmp/pid ]; do
    sleep 1
done
pid=$(cat /tmp/pid)
echo "pid: $pid"

### 2 ###
ip link add vguest_$number link vmain_$num_orchestrator type macvlan mode bridge
ip link set vguest_$number netns $pid

### 3 ###
nsenter -t $pid --net --user --uts --preserve-credential dhclient -4 -1 vguest_$number

### 4 ###
nsenter -t $pid --net --user --uts --preserve-credential chroot containers/bash_container/ bash -c 'while :;do :;done' &


## Cgroup
echo "Cgroup -> /sys/fs/cgroup/orchestrator_$num_orchestrator/app_$number"

mkdir /sys/fs/cgroup/orchestrator_$num_orchestrator/app_$number

# ls /sys/fs/cgroup/orchestrator_$num_orchestrator/app_$number
# sleep 1

echo +cpuset | tee /sys/fs/cgroup/orchestrator_$num_orchestrator/app_$number/cgroup.subtree_control
echo +memory | tee /sys/fs/cgroup/orchestrator_$num_orchestrator/app_$number/cgroup.subtree_control

# echo $pid > /sys/fs/cgroup/orchestrator_$num_orchestrator/app_$number/cgroup.procs

# # Memory
# echo $((40 * 1024 * 1024)) > /sys/fs/cgroup/orchestrator_$num_orchestrator/app_$number/memory.limit_in_bytes

# # Cpu
# echo $num_orchestrator > /sys/fs/cgroup/orchestrator_$num_orchestrator/app_$number/cpuset.cpus
