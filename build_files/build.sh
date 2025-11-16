#!/bin/bash

set -ouex pipefail

# Install from Fedora

dnf5 install -y tmux

# Install from COPR

dnf5 -y copr enable fcsm/tmuxinator
dnf5 -y install tmuxinator
dnf5 -y copr disable fcsm/tmuxinator

# Clean up

dnf5 clean all
