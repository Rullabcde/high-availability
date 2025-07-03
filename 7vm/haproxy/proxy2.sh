#!/bin/bash

# Update Repositories
apt update && apt upgrade -y

# Install HAProxy
apt install haproxy -y
rm -rf /etc/haproxy/haproxy.cfg
cat <<EOF > /etc/haproxy/haproxy.cfg
frontend http_front
    bind *:80
    default_backend http_back
    timeout client 30s

backend http_back
    balance roundrobin
    server web1 ip-app:8081 check
    server web2 ip-app:8082 check
    timeout connect 10s
    timeout server 30s

listen monitoring
    bind *:8080
    mode http
    stats enable
    stats hide-version
    stats refresh 10s
    stats show-node
    stats auth admin:admin
    stats uri /monitoring
    timeout connect 10s
    timeout client 30s
    timeout server 30s
EOF

systemctl enable haproxy
systemctl start haproxy

# Install Keepalived
apt install keepalived -y
apt install build-essential libssl-dev
cd ~
wget http://www.keepalived.org/software/keepalived-1.2.19.tar.gz
tar xzvf keepalived*
cd keepalived*
./configure
make
make install
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

    unicast_src_ip ip-mesin
    unicast_peer {
        ip-pasangan
    }

    virtual_ipaddress {
        ip-virtual
    }

    track_script {
        chk_haproxy
    }
}
EOF

systemctl enable keepalived
systemctl start keepalived
