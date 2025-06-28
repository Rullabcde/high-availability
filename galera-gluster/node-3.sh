#!/bin/bash

apt update && apt upgrade -y
apt install chrony -y
cat <<EOF > /etc/chrony/chrony.conf
server time.google.com iburst
EOF
systemctl restart chrony
apt install curl gnupg -y
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=10.6
apt update
apt install mariadb-server -y
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

wsrep_node_address="node3"
wsrep_node_name="mariadb3"
EOF

sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl stop mariadb
systemctl start mariadb
mysql -u root -prullabcd -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

apt install glusterfs-server -y
systemctl enable --now glusterd
fdisk /dev/sdb
mkfs.xfs /dev/sdb1
mkdir -p /gluster
mount /dev/sdb1 /gluster
gluster pool list
mkdir -p /gluster/wp-shared
