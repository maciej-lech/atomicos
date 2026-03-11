#!/usr/bin/bash

set -eoux pipefail

dnf5 install -y \
  davfs2 \
  dhcpcd \
  firewall-config \
  iwd \
  NetworkManager-team \
  samba \
  samba-common-tools \
  samba-dcerpc \
  samba-ldb-ldap-modules \
  samba-libs \
  samba-winbind \
  samba-winbind-clients \
  samba-winbind-modules \
  socat \
  usbip

dnf5 config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf5 install -y tailscale
dnf5 config-manager setopt tailscale-stable.enabled=0

systemctl enable tailscaled.service
