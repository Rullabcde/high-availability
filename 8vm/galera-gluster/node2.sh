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

wsrep_node_ADDRESS="node2"
wsrep_node_name="mariadb2"
EOF

sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Start MariaDB
systemctl start mariadb
systemctl enable mariadb

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