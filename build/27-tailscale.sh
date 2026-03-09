#!/usr/bin/bash

set -eoux pipefail

dnf5 config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf5 install -y tailscale
dnf5 config-manager setopt tailscale-stable.enabled=0

systemctl enable tailscaled.service
