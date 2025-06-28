#!/bin/bash

apt update && apt upgrade -y
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
cat <<EOF > docker-compose.yml
version: "3.3"
services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: unless-stopped
    environment:
      WORDPRESS_DB_HOST: ip-proxysql:6033
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: rullabcd
      WORDPRESS_DB_PASSWORD: rullabcd
    volumes:
      - ./wordpress:/var/www/html
    ports:
      - "80:80"
EOF
docker compose up -d
apt install glusterfs-client
mount -t glusterfs node1:/wp /wordpress/wp-content/uploads
df -h
