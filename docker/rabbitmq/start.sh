#!/usr/bin/env bash

# XXX Something wrong with upstream package, can't use /usr/lib/rabbitmq/bin/rabbitmq-server.
exec sh -x /usr/lib/rabbitmq/lib/rabbitmq_server-*/sbin/rabbitmq-server
