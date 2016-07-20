#!/usr/bin/env bash
set -eux
set -o pipefail

# With env file we can have working rabbitmqctl, i.e. for health-checks
# XXX Get PodIP instead of using hostname
cat <<EOF > /etc/rabbitmq/rabbitmq-env.conf
NODENAME=rabbit@$(hostname -I | tr -d ' ')
RABBITMQ_USE_LONGNAME=true
EOF

# XXX Something wrong with upstream package, can't use /usr/lib/rabbitmq/bin/rabbitmq-server.
sh -x /usr/lib/rabbitmq/lib/rabbitmq_server-*/sbin/rabbitmq-server
