CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER 'rullabcd'@'%' IDENTIFIED BY 'rullabcd';
GRANT ALL PRIVILEGES ON *.* TO 'rullabcd'@'%' WITH GRANT OPTION;

CREATE USER 'monitor'@'%' IDENTIFIED BY 'monitor';
GRANT USAGE ON *.* TO 'monitor'@'%';
GRANT SELECT ON mysql.user TO 'monitor'@'%';

FLUSH PRIVILEGES;