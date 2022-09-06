#!/usr/bin/env bash

set -e
set -x

echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
echo "libc6:amd64 libraries/restart-without-asking boolean true" | sudo debconf-set-selections
echo "libssl1.1:amd64 libssl1.1/restart-services string" | sudo debconf-set-selections
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    htop \
    libreadline-dev \
    libssl-dev \
    linux-headers-"$(uname -r)" \
    mg \
    unzip \
    zlib1g-dev

# Check for /etc/rc.local and create if needed. This has been deprecated in
# Debian 9 and later. So we need to resolve this in order to regenerate SSH host
# keys.
# FIXME: https://www.linuxbabe.com/linux-server/how-to-enable-etcrc-local-with-systemd
if [ ! -f /etc/rc.local ]; then
    sudo bash -c "echo '#!/bin/sh -e' > /etc/rc.local"
    sudo bash -c "echo 'test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server' >> /etc/rc.local"
    sudo bash -c "echo 'exit 0' >> /etc/rc.local"
    sudo chmod +x /etc/rc.local
    sudo systemctl daemon-reload
    sudo systemctl enable rc-local
    sudo systemctl start rc-local
else
    sudo bash -c "sed -i -e 's|exit 0||' /etc/rc.local"
    sudo bash -c "sed -i -e 's|.*test -f /etc/ssh/ssh_host_dsa_key.*||' /etc/rc.local"
    sudo bash -c "echo 'test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server' >> /etc/rc.local"
    sudo bash -c "echo 'exit 0' >> /etc/rc.local"
fi

# FIXME: Move to cleanup.sh
# Fix machine-id issue with duplicate IP addresses being assigned
if [ -f /etc/machine-id ]; then
    sudo truncate -s 0 /etc/machine-id
fi
