#!/usr/bin/bash

set -eoux pipefail

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

dnf5 config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
# TODO: remove --releasever=43 once Docker publishes F44 packages
# https://github.com/docker/for-linux/issues/1560
dnf5 -y install --enablerepo=docker-ce-stable --releasever=43 \
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
