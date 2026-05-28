#!/usr/bin/bash

set -eoux pipefail

dnf5 install -y \
	ccache \
	debugedit \
	dwz \
	elfutils \
	flatpak-builder \
	gcc-c++ \
	gdb-minimal \
	git-credential-libsecret \
	git-lfs \
	git-subtree \
	git-svn \
	osbuild \
	osbuild-selinux \
	patch \
	python3-pip \
	subversion

# Required by code-on-incus nft monitoring
dnf5 install -y systemd-devel
