#!/bin/bash

# Update Repositories
apt update && apt upgrade -y

# Install Docker
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
  wordpress1:
    image: wordpress:latest
    container_name: wordpress1
    restart: unless-stopped
    ports:
      - "8081:80"
    environment:
      WORDPRESS_DB_HOST: ip-proxysql:6033
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: rullabcd
      WORDPRESS_DB_PASSWORD: rullabcd
    volumes:
      - ./wordpress:/var/www/html
#      - ./gluster:/var/www/html/wp-content/uploads


  wordpress2:
    image: wordpress:latest
    container_name: wordpress2
    restart: unless-stopped
    ports:
      - "8082:80"
    environment:
      WORDPRESS_DB_HOST: ip-proxysql:6033
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: rullabcd
      WORDPRESS_DB_PASSWORD: rullabcd
    volumes:
      - ./wp_data:/var/www/html
#      - ./gluster:/var/www/html/wp-content/uploads
EOF

docker compose up -d

# Install GlusterFS Client
apt install glusterfs-client
mkdir -p wp-shared
mount -t glusterfs node1:/gluster/wp wp-shared
chown -R www-data:www-data wp-shared
chmod -R 775 wp-shared
df -h