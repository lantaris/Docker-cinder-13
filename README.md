# docker-cinder-13

### Cinder + keystone container used for link oVirt 4.1/4.2 (0.0.1) and SDS Ceph V13(mimic) RBD


Directory '/etc/eph' must contain ceph.conf and the key for the ceph cluster user "cinder".

Simple start:

docker run --restart=always -d --name docker-cinder-13 \
-h "HOSTNAME" \
-v /etc/ceph:/etc/ceph \
-v /opt/docker/cinder/log:/var/log \
-p 35357:35357 -p 8776:8776 -p 5000:5000 \
lantaris/docker-cinder-13

"HOSTNAME" - hostname for cinder container

Advanced run:

docker run --restart=always -d --name docker-cinder-13 \
-h "HOSTNAME" \
-e ADMIN_PASS=ADMIN_PASS \
-e CINDER_PASS=CINDER_PASS \
-e RBD_USER=cinder \
-e RBD_POOL=volumes \
-e CEPH_CLUSTER=ceph \
-e RBD_SECRET_UUID=457eb676-33da-42ec-9a8c-9293d545c111 \
-v /opt/docker/cinder/etc/cinder:/etc/cinder \
-v /etc/ceph:/etc/ceph \
-v /opt/docker/cinder/etc/keystone:/etc/keystone \
-v /opt/docker/cinder/lib/cinder:/var/lib/cinder \
-v /opt/docker/cinder/lib/mysql:/var/lib/mysql \
-v /opt/docker/cinder/lib/keystone:/var/lib/keystone \
-v /opt/docker/cinder/log:/var/log \
-p 35357:35357 -p 8776:8776 -p 5000:5000 \
lantaris/docker-cinder-13

"HOSTNAME" - hostname for cinder container

ADMIN_PASS - keystone administrator user password (Default: ADMIN_PASS)

CINDER_PASS - cinder user password (Default: CINDER_PASS)

RBD_USER - Cinder rbd_user parameter (Default: cinder)

RBD_POOL - Cinder rbd_pool parameter (Default: volumes)

CEPH_CLUSTER - Ceph cluster name /etc/ceph/<ceph cluster>.conf (Default: ceph)
  
RBD_SECRET_UUID - Cinder rbd_secret_uuid parameter 
                   (Default value autogenerate. See: 'docker exec ovirt-cinder-4.1 cat /etc/cinder/cinder.conf |grep rbd_secret_uuid')


Detailed starting log:

tail -f /opt/docker/cinder/log/supervisor/prepare.out.log
