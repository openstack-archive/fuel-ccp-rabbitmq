#!/bin/bash

# bootstrap
sudo chown -R rabbitmq: /var/lib/rabbitmq
sudo chown -R rabbitmq: /etc/rabbitmq
echo "${RABBITMQ_CLUSTER_COOKIE}" > /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie

# delme in future
sed -i "s/IPADDR_COMMAS/`hostname -i | sed 's/\./,/g'`/g" /etc/rabbitmq/rabbitmq.config
sed -i "s/IPADDR/`hostname -i`/g" /etc/rabbitmq/rabbitmq.config
sed -i "s/RABBITMQ_CLUSTER_COOKIE/$RABBITMQ_CLUSTER_COOKIE/g" /etc/rabbitmq/rabbitmq.config

# run daemon
rabbitmq-server
