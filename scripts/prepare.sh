#!/bin/bash

# Initialisation enviroment variables
echo "* Initialisation enviroment variables"
export ADMIN_PASS=${ADMIN_PASS:-"ADMIN_PASS"}
export CINDER_PASS=${CINDER_PASS:-"CINDER_PASS"}
export RBD_USER=${RBD_USER:-"cinder"}
export RBD_POOL=${RBD_POOL:-"volumes"}
export CEPH_CLUSTER=${CEPH_CLUSTER:-"ceph"}
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://${HOSTNAME}:35357/v2.0/
export OS_IDENTITY_API_VERSION=2.0
export OS_VOLUME_API_VERSION=2


# Waiting MySQL start
echo -n "Waiting Mysql start - "
while [ -z "$MYSQLFLAG" ]; do
 echo -n "."
 RES=`mysql -e 'use mysql' >/dev/null 2>&1`
 [ $? == 0 ] && MYSQLFLAG="1"
 sleep 1
done
echo "DONE"

echo "* Check /etc/cinder/cinder.conf"
if [ ! -f /etc/cinder/cinder.conf ]; then
 export RBD_SECRET_UUID=${RBD_SECRET_UUID:-`uuidgen`}
 echo "*** Not exist. Writing /etc/cinder/cinder.conf..."
 j2 -f env  /etc/cinder/cinder.conf.tmpl > /etc/cinder/cinder.conf
 chown -R root.cinder /etc/cinder
fi

echo "* Check /etc/keystone/keystone.conf"
[ ! -f /etc/keystone/keystone.conf ] && echo "*** Not exist. Writing /etc/keystone/keystone.conf..." && j2 -f env  /etc/keystone/keystone.conf.tmpl > /etc/keystone/keystone.conf && chown -R root.keystone /etc/keystone

#
# Prepare global variables
#
echo "* Create /bash-admin.sh"
cat << EOF > /bash-admin.sh
export ADMIN_PASS=${ADMIN_PASS}
export CINDER_PASS=${CINDER_PASS}
export RBD_USER=${RBD_USER}
export RBD_POOL=${RBD_POOL}
export CEPH_CLUSTER=${CEPH_CLUSTER}
export RBD_SECRET_UUID=${RBD_SECRET_UUID}

export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://${HOSTNAME}:35357/v2.0/
export OS_IDENTITY_API_VERSION=2.0
export OS_VOLUME_API_VERSION=2
bash
EOF
chmod +x /bash-admin.sh

echo "* Create /bash-cinder.sh"
cat << EOF > /bash-cinder.sh
export ADMIN_PASS=${ADMIN_PASS}
export CINDER_PASS=${CINDER_PASS}
export RBD_USER=${RBD_USER}
export RBD_POOL=${RBD_POOL}
export CEPH_CLUSTER=${CEPH_CLUSTER}
export RBD_SECRET_UUID=${RBD_SECRET_UUID}

export OS_USERNAME=cinder
export OS_PASSWORD=${CINDER_PASS}
export OS_PROJECT_NAME=service
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://${HOSTNAME}:35357/v2.0/
export OS_IDENTITY_API_VERSION=2.0
export OS_VOLUME_API_VERSION=2
bash
EOF
chmod +x /bash-cinder.sh

#
# Keystone prepare
#
# Check database exist
RES=`mysql -e 'use keystone'` >/dev/null 2>&1
if [ $? != 0 ]; then
  echo -n "Database 'keystone' not exist. Creating = "
  /usr/bin/mysqladmin create keystone >/dev/null 2>&1
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi
  echo -n "Set grants for keystone database = "
  echo "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';" | /usr/bin/mysql >/dev/null 2>&1
  echo "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';" | /usr/bin/mysql >/dev/null 2>&1
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi

  echo -n "Syncyng keystone database = "
  /bin/su -s /bin/sh -c "keystone-manage db_sync" keystone
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi

  echo -n "Init farnet = "
  keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
  keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi

  echo -n "Bootstrap the Identity service = "
  keystone-manage bootstrap --bootstrap-password ${ADMIN_PASS} \
       --bootstrap-admin-url http://${HOSTNAME}:35357/v2.0/ \
       --bootstrap-internal-url http://${HOSTNAME}:5000/v2.0/ \
       --bootstrap-public-url http://${HOSTNAME}:5000/v2.0/ \
       --bootstrap-region-id RegionOne
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi

  echo -n "Wait apache start = "
  /usr/local/bin/wait-for-it.sh localhost:80 -t 30
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi

  echo  "Create Service Project "
  openstack -v project create --description "Service Project" service
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi

fi

#
#  Cinder prepare
#
RES=`mysql -e 'use cinder' >/dev/null 2>&1`
if [ $? != 0 ]; then

  echo -n "Database 'cinder' not exist. Creating = "
  /usr/bin/mysqladmin create cinder >/dev/null 2>&1
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi
  echo -n "Set grants for cinder database = "
  echo "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'CINDER_DBPASS';" | /usr/bin/mysql >/dev/null 2>&1
  echo "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'CINDER_DBPASS';" | /usr/bin/mysql >/dev/null 2>&1  
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi

  echo "Create user cinder = "
  openstack user create --password "$CINDER_PASS" cinder
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi  

  echo "Cinder to admin role = "
  openstack role add --project service --user cinder admin
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi  

  echo "Create volumev2 service = "
  openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi  

  echo "Create volumev3 service = "
  openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi  

  echo "Create endpoint volumev2 = "
  openstack endpoint create --region RegionOne volumev2 \
      --publicurl http://${HOSTNAME}:8776/v2/%\(project_id\)s \
      --adminurl http://${HOSTNAME}:8776/v2/%\(project_id\)s \
      --internalurl http://${HOSTNAME}:8776/v2/%\(project_id\)s
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi

  echo "Create endpoint volumev3 = "
  openstack endpoint create --region RegionOne volumev3 \
      --publicurl http://${HOSTNAME}:8776/v3/%\(project_id\)s \
      --adminurl http://${HOSTNAME}:8776/v3/%\(project_id\)s \
      --internalurl http://${HOSTNAME}:8776/v3/%\(project_id\)s
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi

  echo -n "Sync cinder db = "
  su -s /bin/sh -c "cinder-manage db sync" cinder
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi  

  echo -n "Starting cinder-volume = "
  supervisorctl start cinder-volume

  echo -n "Starting cinder-api = "
  supervisorctl start cinder-api

  echo -n "Starting cinder-sheduler = "
  supervisorctl start cinder-sheduler

  echo -n "Wait cinder start = "
  /usr/local/bin/wait-for-it.sh localhost:8776 -t 30
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi

  echo "Crate type ceph = "
  cinder type-create ceph
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi  

  echo "Assign type ceph on backend ceph = "
  cinder type-key ceph set volume_backend_name=ceph
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi  

  echo "Setting quota volumes,snapshots to 9999 = "
  cinder quota-update --volumes 9999 --snapshots 9999 --gigabytes 9999 $(openstack project show -f value -c id service)
  if [ $? == 0 ]; then echo "DONE"; else echo "ERROR"; fi  

  echo "---=== Prepare finished ===---"

else

  echo "---=== Restarting cinder services ===---"
  echo  "Restarting cinder-volume = "
  supervisorctl start cinder-volume
  
  echo  "Restarting cinder-api = "
  supervisorctl start cinder-api
  
  echo  "Restarting cinder-sheduler = "
  supervisorctl start cinder-sheduler

fi