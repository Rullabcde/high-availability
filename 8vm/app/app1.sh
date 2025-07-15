#!/bin/bash
set -e

# Update system
apt update && apt upgrade -y

# Install dependencies
apt install -y nginx php php-cli php-fpm php-mysql php-opcache php-mbstring php-xml php-gd php-curl

# Download and extract WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz 
tar -xzvf latest.tar.gz
rm -rf /var/www/wordpress
mv wordpress /var/www/
chown -R www-data:www-data /var/www/wordpress
chmod -R 755 /var/www/wordpress

# Configure Nginx
cat <<EOF > /etc/nginx/sites-available/wordpress
server {
    listen 80;
    server_name _;
    root /var/www/wordpress;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }
}
EOF

# Enable site
rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/

systemctl restart nginx

# Install GlusterFS
apt install glusterfs-client -y

# Mount GlusterFS
mount -t glusterfs node1:/wp /var/www/wordpress/wp-content/uploads || echo "GlusterFS mount failed"
chown -R www-data:www-data /var/www/wordpress/wp-content/uploads
chmod -R 775 /var/www/wordpress/wp-content/uploads
df -h