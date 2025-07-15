#!/bin/bash
set -e

# Update system
apt update && apt upgrade -y

# Install Docker and Docker Compose
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
docker compose up -d

# Install GlusterFS
apt install glusterfs-server -y
systemctl enable glusterd --now

# Format disk
fdisk /dev/sdb <<EOF
n
p
1


t
7
w
EOF
mkfs.xfs /dev/sdb1 || true
mkdir -p /gluster
mount /dev/sdb1 /gluster
mkdir -p /gluster/wp-shared

# # Create Gluster Volume
# gluster peer probe node2 || echo "Node2 already connected"
# gluster peer probe node3 || echo "Node3 already connected"
# gluster volume create wp replica 3 node1:/gluster/wp-shared node2:/gluster/wp-shared node3:/gluster/wp-shared force
# gluster volume start wp
# gluster volume info wp