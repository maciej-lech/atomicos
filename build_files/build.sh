#!/bin/bash

set -ouex pipefail

# Enable COPR repos
dnf5 -y copr enable fcsm/tmuxinator
dnf5 -y copr enable scottames/ghostty
dnf5 -y copr enable ryanabx/cosmic-epoch

# Install packages
dnf5 install -y \
  @cosmic-desktop \
  @cosmic-desktop-apps \
  ghostty \
  helix \
  tmux \
  tmuxinator

# Disable COPR repos
dnf5 -y copr disable fcsm/tmuxinator
dnf5 -y copr disable scottames/ghostty
dnf5 -y copr disable ryanabx/cosmic-epoch

# Clean up
dnf5 clean all
