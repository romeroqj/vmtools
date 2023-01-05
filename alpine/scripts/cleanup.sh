#!/usr/bin/env bash

set -e
set -x

# Clear APT cache
sudo apt-get clean

# Clear audit logs
if [ -f /var/log/audit/audit.log ]; then
  sudo bash -c "cat /dev/null > /var/log/audit/audit.log"
fi
if [ -f /var/log/wtmp ]; then
  sudo bash -c "cat /dev/null > /var/log/wtmp"
fi
if [ -f /var/log/lastlog ]; then
  sudo bash -c "cat /dev/null > /var/log/lastlog"
fi

# Cleanup persistent udev rules
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
  sudo rm /etc/udev/rules.d/70-persistent-net.rules
fi

# Cleanup /tmp
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Cleanup ssh keys
sudo rm -f /etc/ssh/ssh_host_*

# Reset hostname
sudo bash -c "cat /dev/null > /etc/hostname"

# Cleanup shell history
history -w
history -c
