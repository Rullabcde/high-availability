#!/bin/bash

# Update Repositories
apt update && apt upgrade -y

# Install HAProxy
sudo apt install haproxy -y
nano /etc/haproxy/haproxy.cfg
systemctl enable haproxy
systemctl start haproxy

# Install Keepalived
apt install keepalived -y
apt install build-essential libssl-dev
cd ~
wget http://www.keepalived.org/software/keepalived-1.2.19.tar.gz
tar xzvf keepalived*
cd keepalived*
./configure
make
make install
nano /etc/keepalived/keepalived.conf
systemctl enable keepalived
systemctl start keepalived
