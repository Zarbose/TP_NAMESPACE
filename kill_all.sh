#!/bin/bash

sudo kill -9 $(ps aux | grep 'sleep infinity' | tr -s ' ' | cut -d ' ' -f 2)
sudo kill -9 $(ps aux | grep 'bash ./echo_pid.sh' | tr -s ' ' | cut -d ' ' -f 2)
sudo kill -9 $(ps aux | grep 'while :;do :;done' | tr -s ' ' | cut -d ' ' -f 2)
sudo kill -9 $(ps aux | grep '/sbin/dhcpd' | tr -s ' ' | cut -d ' ' -f 2)

rm -rf dhcpd_*

number=$(cat /tmp/cpt)
number2=$(cat /tmp/orchestrator_$number/cpt)
for ((i=1; i<=$number; i++)); do
    for ((j=1; j<=$number2; j++)); do
        sudo rmdir /sys/fs/cgroup/orchestrator_$i/app_$j
    done
    sudo rmdir /sys/fs/cgroup/orchestrator_$i
    sudo rm -rf /tmp/orchestrator_$i
done

echo "0" > /tmp/cpt
