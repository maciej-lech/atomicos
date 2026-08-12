#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/repo-helpers.sh

dnf5 install -y \
	distrobox \
	edk2-ovmf \
	incus \
	incus-agent \
	libvirt \
	libvirt-dbus \
	libvirt-nss \
	lxc \
	podman-compose \
	podman-machine \
	podman-tui \
	qemu \
	qemu-user-binfmt \
	qemu-user-static \
	swtpm \
	swtpm-tools \
	udica \
	virt-install \
	virt-manager \
	virt-v2v \
	virt-viewer

systemctl enable podman.socket

# TODO: remove --releasever=44 once Docker publishes F45 packages
dnf_repo_install_isolated https://download.docker.com/linux/fedora/docker-ce.repo \
	--enablerepo=docker-ce-stable --releasever=44 \
	containerd.io \
	docker-buildx-plugin \
	docker-ce \
	docker-ce-cli \
	docker-compose-plugin \
	docker-model-plugin

systemctl enable docker.socket

cat >/usr/lib/sysusers.d/docker.conf <<'SYSUSERS'
g docker -
SYSUSERS
