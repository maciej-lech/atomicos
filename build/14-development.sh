#!/usr/bin/bash

set -eoux pipefail

dnf5 install -y \
  ccache \
  debugedit \
  dwz \
  elfutils \
  flatpak-builder \
  gdb-minimal \
  git-credential-libsecret \
  git-lfs \
  git-subtree \
  git-svn \
  libxcrypt-compat \
  mkisofs \
  osbuild \
  osbuild-selinux \
  patch \
  python3-pip \
  python3-rpm \
  python3-systemd \
  schily-libs \
  subversion
