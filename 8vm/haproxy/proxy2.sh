#!/bin/bash
set -e

apt update && apt upgrade -y

# Install HAProxy
apt install -y haproxy
rm -f /etc/haproxy/haproxy.cfg

cat <<EOF > /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5s
    timeout client 30s
    timeout server 30s

frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    server web1 app1:80 check
    server web2 app2:80 check

listen monitoring
    bind *:8080
    mode http
    stats enable
    stats hide-version
    stats refresh 10s
    stats show-node
    stats auth admin:admin
    stats uri /monitoring
EOF

systemctl enable haproxy
systemctl start haproxy

# Install Keepalived
apt install -y keepalived build-essential libssl-dev

cat <<EOF > /etc/keepalived/keepalived.conf
global_defs {
    enable_script_security
    router_id HAPROXY_2
}

vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight -2
    fall 3
    rise 2
    user root
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens18
    virtual_router_id 101
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass nginx123
    }
    unicast_src_ip YOUR_IP_HERE
    unicast_peer {
        PEER_IP_HERE
    }
    virtual_ipaddress {
        VIRTUAL_IP_HERE
    }
    track_script {
        chk_haproxy
    }
}
EOF

systemctl enable keepalived
systemctl start keepalived