#!/bin/bash

set -ouex pipefail

# Enable COPR repos
dnf5 -y copr enable fcsm/tmuxinator
dnf5 -y copr enable scottames/ghostty
dnf5 -y copr enable gmaglione/podman-bootc

# Install packages
dnf5 install -y \
  fsverity-utils \
  ghostty \
  helix \
  podman-bootc \
  tmux \
  tmuxinator

# Disable COPR repos
dnf5 -y copr disable gmaglione/podman-bootc
dnf5 -y copr disable scottames/ghostty
dnf5 -y copr disable fcsm/tmuxinator
