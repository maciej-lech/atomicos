#!/bin/bash

set -ouex pipefail

# Enable COPR repos
dnf5 -y copr enable avengemedia/dms

# Install packages
dnf5 install -y \
  cliphist \
  dgop \
  dms \
  dsearch \
  matugen \
  niri

# Disable COPR repos
dnf5 -y copr disable avengemedia/dms
