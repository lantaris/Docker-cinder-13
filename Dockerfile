################################################################
#                                                              #
#                 Dockerfile for Cinder + keystone             #
#                                                              #
################################################################

FROM centos:7

LABEL maintainer="edik.ponomarenko@mail.ru" name="Cinder + keystone container is used for link Virt 4.1/4.2 (0.0.1) and SDS Ceph V13(mimic) RBD (based on CenOS 7)" vendor="Lantaris" license="GPLv2" build-date=""20181005"" version="0.0.1"

########################################################
#                        INSTALLING                    #
########################################################
RUN yum clean all && yum -y install epel-release &&yum -y update &&\
    yum -y install centos-release-openstack-pike yum-utils https://download.ceph.com/rpm-mimic/el7/noarch/ceph-release-1-1.el7.noarch.rpm &&\
    yum-config-manager --disable centos-ceph-jewel &&\
    yum -y install ceph openstack-cinder openstack-keystone python2-openstackclient rabbitmq-server \
                   mariadb-server httpd mod_wsgi supervisor python-pip sed which &&\
    pip install j2cli &&\
    yum -y clean all &&\
    rm -rf /var/cache/yum

# Add configuration
RUN ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
RUN rm -f /etc/keystone/keystone.conf
RUN rm -f /etc/cinder/cinder.conf
ADD etc/cinder/* /etc/cinder/
ADD etc/keystone/* /etc/keystone/
ADD etc/my.cnf.d/* /etc/my.cnf.d/

# Container init scripts
ADD scripts/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Backuping configuration files
RUN cp -rfp /etc/cinder /etc/cinder.orig &&\
    cp -rfp /etc/keystone /etc/keystone.orig &&\
    cp -rfp /etc/httpd /etc/httpd.orig &&\
    cp -rfp /var/log /var/log.orig 

###################################
#      Supervisord ini files      #
###################################
ADD supervisor/* /etc/supervisord.d/

EXPOSE 35357 8776 5000

VOLUME /var/lib/mysql
VOLUME /var/log
VOLUME /var/lib/cinder
VOLUME /var/lib/keystone

CMD ["/usr/local/bin/entry.sh"]
