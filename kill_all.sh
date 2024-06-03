#!/bin/bash

sudo kill -9 $(ps aux | grep 'sleep infinity' | tr -s ' ' | cut -d ' ' -f 2)
sudo kill -9 $(ps aux | grep 'bash ./echo_pid.sh' | tr -s ' ' | cut -d ' ' -f 2)
sudo kill -9 $(ps aux | grep 'while :;do :;done' | tr -s ' ' | cut -d ' ' -f 2)
sudo kill -9 $(ps aux | grep '/sbin/dhcpd' | tr -s ' ' | cut -d ' ' -f 2)

rm -rf dhcpd_*

number=$(cat /tmp/cpt)
for ((i=1; i<=$number; i++)); do
    sur rm -rf /sys/fs/cgroup/orchestrator_$i
done

echo "0" > /tmp/cpt
