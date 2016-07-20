#!/usr/bin/env bash
set -euo pipefail

TOP=$(pwd)

UPSTREAM_RELEASE=rabbitmq_v3_6_6_milestone5
UPSTREAM_VERSION=3.6.5.905
UPSTREAM_ORIG_SHA=c089b0de62115278b090ed08b8c951bfd3f5d6823a3df42a9ea78179191474b0
UPSTREAM_DEBIAN_SHA=f0ec7b015e7eb471884875f1f3bc7ee048a9132110162253c954cbb4399c792d
UPSTREAM_DSC_SHA=979e8d899fd60fe528564e43a66e86d3c54f30a3a5be47069147319ef97041cd

AUTOCLUSTER_OWNER=binarin
AUTOCLUSTER_REPO=rabbitmq-autocluster
AUTOCLUSTER_REF=health-check-v1
AUTOCLUSTER_SHA=e7cb3bce7fc70f53b5216dc2b2a55102fdf8420b3569c4031d0baaf8590a61d3

AWS_OWNER=gmr
AWS_REPO=rabbitmq-aws
AWS_REF=38eccbee0f5f1a26841dd413418cef4233f8cd55
AWS_SHA=1cb244d14065154772d37470e058f68bb562a34456ccf3864bbc89a802ff3a2d

ensure-file() {
    local file="${1:?}"
    local url="${2:?}"
    local sha_expected="${3:?}"
    if [[ ! -f $file  || "$(sha256sum $file | cut -f 1 -d ' ')" != $sha_expected ]]; then
        wget -O $file $url
    fi
    local sha_got=$(sha256sum $file | cut -f 1 -d ' ')
    if [[ $sha_got != $sha_expected ]]; then
        echo "Checksum mismatch for $file from $url: got $sha_got when $sha_expected was expected"
        return 1
    fi
}

run-builder() {
    docker run --rm -v $TOP:$TOP -w $(pwd) -u $(id -u) rmq-deb-builder "$@"
}

cat Dockerfile | docker build -t rmq-deb-builder - # no context uploaded when building from stdin

ensure-file rabbitmq-server_$UPSTREAM_VERSION-1.dsc https://github.com/rabbitmq/rabbitmq-server/releases/download/$UPSTREAM_RELEASE/rabbitmq-server_$UPSTREAM_VERSION-1.dsc $UPSTREAM_DSC_SHA
ensure-file rabbitmq-server_$UPSTREAM_VERSION-1.debian.tar.gz https://github.com/rabbitmq/rabbitmq-server/releases/download/$UPSTREAM_RELEASE/rabbitmq-server_$UPSTREAM_VERSION-1.debian.tar.gz $UPSTREAM_DEBIAN_SHA
ensure-file rabbitmq-server_$UPSTREAM_VERSION.orig.tar.xz https://github.com/rabbitmq/rabbitmq-server/releases/download/$UPSTREAM_RELEASE/rabbitmq-server_$UPSTREAM_VERSION.orig.tar.xz $UPSTREAM_ORIG_SHA

ensure-file autocluster.tar.gz https://github.com/$AUTOCLUSTER_OWNER/$AUTOCLUSTER_REPO/archive/$AUTOCLUSTER_REF.tar.gz $AUTOCLUSTER_SHA
ensure-file rabbitmq_aws.tar.gz https://github.com/$AWS_OWNER/$AWS_REPO/archive/$AWS_REF.tar.gz $AWS_SHA

rm -rf $TOP/_build/
mkdir -p $TOP/_build/{repack,deb}

# First stage:
# - unpack upstream sources
# - inject dependencies via multiple upstream tarballs feature of dpkg
# - fix some troubles with debian/rules, make this deps available to build process
# - repack everything into new debian source package
cd $TOP/_build/repack
run-builder dpkg-source -x $TOP/rabbitmq-server_$UPSTREAM_VERSION-1.dsc

cp $TOP/autocluster.tar.gz rabbitmq-server_$UPSTREAM_VERSION.orig-autocluster.tar.gz
cp $TOP/rabbitmq_aws.tar.gz rabbitmq-server_$UPSTREAM_VERSION.orig-aws.tar.gz

cd $(find -maxdepth 1 -mindepth 1 -type d)

mkdir debian/patches

cp $TOP/add_autocluster_plugin.diff debian/patches
cat <<'EOF' > debian/patches/series
add_autocluster_plugin.diff
EOF

patch -p1 < $TOP/debian-rules.diff

run-builder dpkg-source -b .

# Second stage - build repacked sources from stage 1
cd $TOP/_build/deb
dpkg-source -x $TOP/_build/repack/*.dsc

cd $(find -maxdepth 1 -mindepth 1 -type d)
run-builder dpkg-buildpackage -us -uc
