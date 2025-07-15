#!/bin/bash
set -e

apt update && apt upgrade -y

# Install ProxySQL
apt install -y lsb-release wget apt-transport-https ca-certificates gnupg
wget -O /usr/share/keyrings/proxysql-2.6.x-keyring.gpg \
'https://repo.proxysql.com/ProxySQL/proxysql-2.6.x/repo_pub_key.gpg '

echo "deb [signed-by=/usr/share/keyrings/proxysql-2.6.x-keyring.gpg] https://repo.proxysql.com/ProxySQL/proxysql-2.6.x/ $(lsb_release -sc)/ ./" | \
tee /etc/apt/sources.list.d/proxysql.list

apt update
apt install -y proxysql=2.6.6

# Configure ProxySQL
cat <<EOF > /etc/proxysql.cnf
datadir="/var/lib/proxysql"
admin_variables=
{
    admin_credentials="admin:admin"
}
mysql_variables=
{
    connect_timeout_server=3000
    monitor_username="monitor"
    monitor_password="monitor"
    monitor_connect_timeout=1000
    monitor_ping_timeout=1000
    monitor_read_only_max_timeout_count=5
}
mysql_servers=
(
    { hostgroup_id=10, hostname="node1", port=3306 },
    { hostgroup_id=20, hostname="node2", port=3306 },
    { hostgroup_id=20, hostname="node3", port=3306 }
)
mysql_users=
(
    { username="rullabcd", password="rullabcd", default_hostgroup=10 },
    { username="monitor", password="monitor", default_hostgroup=10, transaction_persistent=1 }
)
mysql_query_rules=
(
    { rule_id=1, active=1, match_pattern="^SELECT.*", destination_hostgroup=20, apply=1 }
)
EOF

systemctl stop proxysql || true
rm -rf /var/lib/proxysql/proxysql.db
systemctl start proxysql
systemctl enable proxysql

# Load config to runtime
apt install -y mariadb-client

mysql -uadmin -padmin -h127.0.0.1 -P6032 <<EOF
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
EOF

mysql -urullabcd -prullabcd -h127.0.0.1 -P6033 -e "SHOW DATABASES;"