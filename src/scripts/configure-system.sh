#!/bin/sh

# Configure host to rotate DNS servers returned via DHCP
sudo sed -i -e '/^RES_OPTIONS=/{h;s/=.*/="rotate timeout:2 attempts:5"/};${x;/^$/{s//RES_OPTIONS="rotate timeout:2 attempts:5"/;H};x}' /etc/sysconfig/network-scripts/ifcfg-eth0
