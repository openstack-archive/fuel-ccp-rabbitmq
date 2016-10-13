#!/usr/bin/env bash
set -eux
set -o pipefail
# XXX Something wrong with upstream package, can't use /usr/lib/rabbitmq/bin/rabbitmq-server.
# Good file is hidden somewhere in /usr/lib/rabbitmq/lib/rabbitmq_server-*/sbin
RABBITS=(
    $(find /usr/lib/rabbitmq/lib/ -type f -executable -name rabbitmq-server | sort | head -n 1)
    /usr/lib/rabbitmq-server/bin/rabbitmq-server
    /usr/bin/rabbitmq-server
)
for r in "${RABBITS[@]}"; do
    if [[ ! -x $r ]]; then
        continue
    fi
    echo "Using rabbitmq-server script at '$r'"
    exec $r
done

echo "No rabbit executable. Candidates were: ${RABBITS[@]}"
exit 1
