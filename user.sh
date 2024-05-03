#!/bin/bash

unshare --user --net --uts --map-root-user bash

sleep 2

ip l set vmain up

dhclient -1