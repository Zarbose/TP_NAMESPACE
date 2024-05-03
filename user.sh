#!/bin/bash

unshare --user --net --uts --map-root-user bash

sleep 2

# ip addr add 10.0.0.10/24 dev vmain
ip l set vmain up

dhclient -1