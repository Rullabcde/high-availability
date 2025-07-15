#!/bin/bash
set -e

# Update system
apt update && apt upgrade -y

# Install Chrony
apt install -y chrony
echo "server time.google.com iburst" > /etc/chrony/chrony.conf
systemctl restart chrony

# MariaDB Repo Setup
apt install -y curl gnupg
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup  | sudo bash -s -- --mariadb-server-version=10.6
apt update

# Install MariaDB Galera
apt install -y mariadb-server galera-4

# Configure Galera
cat <<EOF > /etc/mysql/conf.d/galera.cnf
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

wsrep_cluster_name="test_cluster"
wsrep_cluster_address="gcomm://node1,node2,node3"

wsrep_sst_method=rsync

wsrep_node_ADDRESS="node1"
wsrep_node_name="mariadb1"
EOF

sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Initialize Cluster
systemctl stop mariadb
galera_new_cluster

# Secure Installation & Create DB
mysql -u root -e "SET GLOBAL innodb_file_per_table = 1;" \
      -e "SET GLOBAL innodb_log_file_size = 512M;" \
      -e "CREATE DATABASE wordpress;" \
      -e "CREATE USER 'rullabcd'@'%' IDENTIFIED BY 'rullabcd';" \
      -e "GRANT ALL PRIVILEGES ON *.* TO 'rullabcd'@'%' WITH GRANT OPTION;" \
      -e "FLUSH PRIVILEGES;"

# Install GlusterFS
apt install -y glusterfs-server
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