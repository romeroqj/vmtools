#!/usr/bin/env bash

# Zero out the free space to save space in the final image
sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm -f /EMPTY

# Sync to ensure that the delete completes before moving on
sudo sync && sudo sync
