#!/bin/bash

sleep 2

ip l set vmain up

dhclient -1

sleep infinity