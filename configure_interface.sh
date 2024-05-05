#!/bin/bash

ip l set vmain up

dhclient -q -1 vmain