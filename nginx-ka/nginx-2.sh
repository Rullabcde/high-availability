#!/bin/bash

apt update && apt upgrade -y
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/rullabcd.key \
  -out /etc/ssl/certs/rullabcd.crt \
  -subj "/C=ID/ST=Yogyakarta/L=Jogja/O=Rull Corp/OU=IT/CN=rullabcd"
apt install nginx -y
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
    router_id NGINX_LB_2
}

vrrp_script chk_nginx {
    script "/usr/bin/curl -f http://localhost/health || exit 1"
    interval 2
    weight -2
    fall 3
    rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface enp0s8  # Ganti sesuai interface di mesin ini
    virtual_router_id 101
    priority 100
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass nginx123
    }

    unicast_src_ip ip-mesin-backup
    unicast_peer {
        ip-mesin
    }

    virtual_ipaddress {
        virtual-ip-address
    }

    track_script {
        chk_nginx
    }
}
EOF
UNTUK YANG BACKUP


systemctl enable keepalived
systemctl start keepalived
rm /etc/nginx/sites-enabled/default
cat <<EOF > /etc/nginx/sites-available/rullabcd.conf
upstream backend_servers {
    server ip-server:80 weight=1 max_fails=3 fail_timeout=30s;
    server ip-server:80 weight=1 max_fails=3 fail_timeout=30s;    
}

server {
    listen 80;
    server_name _;

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name _;

    ssl_certificate     /etc/ssl/certs/rullabcd.crt;
    ssl_certificate_key /etc/ssl/private/rullabcd.key;

    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }

    location /nginx_status {
        stub_status on;
        access_log off;
        allow 10.1.1.0/24;
        deny all;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
ln -sf /etc/nginx/sites-available/rullabcd.conf /etc/nginx/sites-enabled/rullabcd.conf
nginx -t
systemctl restart nginx