#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/repo-helpers.sh

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

dnf_repo_install_isolated https://pkgs.tailscale.com/stable/fedora/tailscale.repo \
	--enablerepo=tailscale-stable tailscale
systemctl enable tailscaled.service

# sshd is off by default; open the port per session with firewall-cmd --add-service=ssh
sed -i '/<service name="ssh"\/>/d' /usr/lib/firewalld/zones/public.xml
