#!/bin/bash

proxysql --foreground &
sleep 5
mysql -u admin -padmin -h 127.0.0.1 -P6032 < /init.sql
wait