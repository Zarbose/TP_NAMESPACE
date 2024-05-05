#!/bin/bash

ip l set vmain up

dhclient -1 -v vmain