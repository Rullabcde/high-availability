#!/bin/bash

# Update Repositories
apt update && apt upgrade -y

# Install GlusterFS
apt install glusterfs-server -y
systemctl enable --now glusterd

# Configure GlusterFS
fdisk /dev/sdb
mkfs.xfs /dev/sdb1
mkdir -p /gluster
mount /dev/sdb1 /gluster
gluster peer probe node2
gluster peer probe node3
gluster pool list
mkdir -p /gluster/wp-shared
gluster volume create wp replica 3 \
node1:/gluster/wp-shared \
node2:/gluster/wp-shared \
node3:/gluster/wp-shared \
force
gluster volume start wp
gluster volume info wp