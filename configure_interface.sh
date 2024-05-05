#!/bin/bash

ip l set vmain up

dhclient -q -4 -1 vmain