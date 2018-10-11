# docker-cinder-13

### Cinder + keystone контейнер для связки системы виртуализации oVirt 4.1/4.2 и SDS Ceph V12(mimic) в режиме RBD


Директория '/etc/ceph' должна содержать ceph.conf(конфигурационный файл Ceph) ключ доступа к пулу RBD для пользователя 'cinder'

Простой запуск контейнера:

docker run --restart=always -d --name docker-cinder-13 \
-h "HOSTNAME" \
-v /etc/ceph:/etc/ceph \
-v /opt/docker/cinder/log:/var/log \
-p 35357:35357 -p 8776:8776 -p 5000:5000 \
lantaris/docker-cinder-13

"HOSTNAME" - имя хоста (должно резовиться в DNS), где разворачивается контейнер.

Расширенный запуск(рекомендуется):

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

"HOSTNAME" - имя хоста (должно резолвиться в DNS), где разворачивается контейнер.

ADMIN_PASS - Пароль администратора связки cinder+keystone (По умолчанию: ADMIN_PASS).
             Вход в контейнер в режиме администратора ( docker exec -ti docker-cinder-13 bash "/bash-admin.sh" )

CINDER_PASS - Пароль пользователя cinder (По умолчанию: CINDER_PASS).
              Вход в контейнер под пользователем 'cinder' ( docker exec -ti docker-cinder-13 bash "/bash-cinder.sh" )

RBD_USER - Имя пользователя для доступа к пулу с томами, указанному в переменной RBD_POOL (По умолчанию: cinder)

RBD_POOL - Имя пула с томами (По умолчанию: volumes)

CEPH_CLUSTER - Имя кластера Ceph /etc/ceph/<ceph cluster>.conf (По умолчанию: ceph)
  
RBD_SECRET_UUID - UUID сервиса Cinder. (Указывается в дальнейшем в oVirt). По умолчанию генерируется автоматически.
                  (Получить сгенерированный UUID можно следующим образом 'docker exec docker-cinder-13 cat /etc/cinder/cinder.conf |grep rbd_secret_uuid)


## Первый старт может занять продолжительное время 10-15 мин.

Детальный мониторинг первого старта:

tail -f /opt/docker/cinder/log/supervisor/prepare.out.log

## Что прописывается в oVirt

На всех нодах должен быть установлен базовый набор Ceph. В каталоге /etc/ceph/ должен быть конфигурационный файл кластера Ceph и ключь пользователя, которому открыт доступ к пулу c RBD указанному в переменной контейнера (RBD_USER)

1. В разделе "External Providers" добавляем нового провайдера.
2. Name - указываем любое удобное имя.
3. Type - OpenStack Volume
4. Provider URL - http://<имя хоста с контейнером>:8776
5. Requires Authentication - устанавливаем флаг.
6. Username - cinder
7. Password - указываем раннее заданый пароль для переменной (CINDER_PASS)
8. Tenant Name - service
9. Authentication URL - http://<имя хоста с контейнером>:35357/v2.0/

**Нажимаем TEST. Если тест прошел удачно, сохраняем настройки.

**Становимся на вновь созданную запись внешнего провайдера.

**Переходим в закладку "Authentication Keys", добавляем новую запись

1. UUID - раннее указанный UUID в переменной (RBD_SECRET_UUID)
2. Value - ключь пользователя, раннее указанного в переменной (RBD_USER). 

** Сохраняем настройки, пользуемся.
