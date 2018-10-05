#!/bin/sh

echo "-== Prepare starting Cinder services ==-"

#/var/log
[ ! -d /var/log/supervisor ] &&  echo "'/var/log/supervisor' not found. Restoring from original." && cp -rfp /var/log.orig/supervisor /var/log
[ ! -d /var/log/httpd ] &&  echo "'/var/log/httpd' not found. Restoring from original." && cp -rfp /var/log.orig/httpd /var/log
[ ! -d /var/log/mariadb ] &&  echo "'/var/log/mariadb' not found. Restoring from original." && cp -rfp /var/log.orig/mariadb /var/log
[ ! -d /var/log/keystone ] &&  echo "'/var/log/keystone' not found. Restoring from original." && cp -rfp /var/log.orig/keystone /var/log
[ ! -d /var/log/cinder ] &&  echo "'/var/log/cinder' not found. Restoring from original." && cp -rfp /var/log.orig/cinder /var/log
[ ! -d /var/log/rabbitmq ] &&  echo "'/var/log/rabbitmq' not found. Restoring from original." && cp -rfp /var/log.orig/rabbitmq /var/log


echo "-======= Prepare template configuration =====-"
[ ! -f /etc/cinder/cinder.conf.tmpl ] && echo "Restore from orig /etc/cinder/cinder.conf.tmpl..." && cp -rfp  /etc/cinder.orig/* /etc/cinder
[ ! -f /etc/keystone/keystone.conf.tmpl ] && echo "Restore from orig /etc/keystone/keystone.conf.tmpl..." && cp -rfp  /etc/keystone.orig/* /etc/keystone

echo "-======== Fix permission =============-"
echo "* Chown /var/lib/mysql"
chown -R mysql.mysql /var/lib/mysql

echo "* Chown Cinder"
mkdir -p /var/lib/cinder/groups
mkdir -p /var/lib/cinder/tmp
chown -R cinder.cinder /var/lib/cinder
chmod -R u=rwX,g=rwX /etc/cinder
chown -R root.cinder /etc/cinder

echo "* Chown keystone"
chmod -R u=rwX,g=rwX /etc/keystone
chown -R root.keystone /etc/keystone
chown -R keystone.keystone /var/lib/keystone

echo "* mkdir /backup"
mkdir -p /backup

echo "-====================================-"
echo "* Runing supervisord"
/usr/bin/supervisord -n -c /etc/supervisord.conf
echo "* Supervisord stoped"
