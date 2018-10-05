#!/bin/sh

[ -f /usr/libexec/mysql-prepare-db-dir ] && echo "--- Runing mysql-prepare-db-dir" && /usr/libexec/mysql-prepare-db-dir mariadb
[ -f /usr/libexec/mariadb-prepare-db-dir ] && echo "--- Runing mariadb-prepare-db-dir" && /usr/libexec/mariadb-prepare-db-dir mariadb
/usr/bin/mysqld_safe --basedir=/usr
