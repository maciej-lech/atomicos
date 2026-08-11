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

# Docker publishes no repo past fedora 44
dnf_repo_install_isolated https://download.docker.com/linux/fedora/docker-ce.repo \
	--fallback-repo-releasever=44 \
	--enablerepo=docker-ce-stable \
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
