#!/usr/bin/bash

set -eoux pipefail

dnf5 install -y \
	davfs2 \
	dhcpcd \
	firewall-config \
	iwd \
	mobile-broadband-provider-info \
	NetworkManager-openconnect \
	NetworkManager-openvpn \
	NetworkManager-ppp \
	NetworkManager-ssh \
	NetworkManager-team \
	NetworkManager-tui \
	NetworkManager-vpnc \
	nm-connection-editor \
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
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/tailscale.repo

systemctl enable tailscaled.service
