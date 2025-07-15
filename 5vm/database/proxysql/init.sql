DELETE FROM mysql_servers;
DELETE FROM mysql_users;
DELETE FROM mysql_query_rules;

INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES
(10, 'db1', 3306),   -- write
(20, 'db2', 3306),   -- read
(20, 'db3', 3306);   -- read

-- User aplikasi
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES
('rullabcd', 'rullabcd', 10);

-- User monitoring
INSERT INTO mysql_users (username, password, default_hostgroup, transaction_persistent) VALUES
('monitor', 'monitor', 10, 1);

-- Query rules
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply) VALUES
(1, 1, '^SELECT .*', 20, 1);

-- Load config ke runtime
LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;

-- Save ke disk
SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;