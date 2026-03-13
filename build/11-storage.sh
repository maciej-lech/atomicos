#!/usr/bin/bash

set -eoux pipefail

dnf5 install -y \
	bcache-tools \
	clevis \
	clevis-luks \
	clevis-pin-tpm2 \
	cryfs \
	device-mapper-multipath \
	fsverity-utils \
	fuse-encfs \
	gvfs \
	gvfs-archive \
	gvfs-fuse \
	gvfs-gphoto2 \
	gvfs-mtp \
	gvfs-nfs \
	gvfs-smb \
	libblockdev-btrfs \
	libblockdev-lvm \
	udisks2-btrfs \
	udisks2-iscsi \
	udisks2-lvm2
