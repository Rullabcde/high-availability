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

wsrep_node_address="node1"
wsrep_node_name="mariadb1"
EOF

sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl stop mariadb
galera_new_cluster
mysql -u root -prullabcd -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
# systemctl start mariadb
mysql -uroot -prullabcd
CREATE DATABASE wordpress;
CREATE USER 'rullabcd'@'%' IDENTIFIED BY 'rullabcd';
GRANT ALL PRIVILEGES ON *.* TO 'rullabcd'@'%' WITH GRANT OPTION;

CREATE USER 'monitor'@'%' IDENTIFIED BY 'monitor';
GRANT USAGE ON *.* TO 'monitor'@'%';
GRANT SELECT ON mysql.user TO 'monitor'@'%';

FLUSH PRIVILEGES;

apt install glusterfs-server -y
systemctl enable --now glusterd
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
