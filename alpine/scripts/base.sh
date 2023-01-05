#!/bin/ash

set -e
set -x

echo "http://eu.edge.kernel.org/alpine/v3.17/main" > /etc/apk/repositories
echo "http://eu.edge.kernel.org/alpine/v3.17/community" >> /etc/apk/repositories
apk update
apk add --latest htop mg unzip


# FIXME: Move to cleanup.sh
# Fix machine-id issue with duplicate IP addresses being assigned
# if [ -f /etc/machine-id ]; then
#     sudo truncate -s 0 /etc/machine-id
# fi
