#!/bin/bash

set -ouex pipefail

# Enable COPR repos
dnf5 -y copr enable fcsm/tmuxinator
dnf5 -y copr enable scottames/ghostty

# Install packages
dnf5 install -y \
  ghostty \
  helix \
  tmux \
  tmuxinator

# Disable COPR repos
dnf5 -y copr disable fcsm/tmuxinator
dnf5 -y copr disable scottames/ghostty

# Clean up
dnf5 clean all
