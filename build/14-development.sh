#!/usr/bin/bash

set -eoux pipefail

dnf5 install -y \
  bcc \
  bcc-tools \
  bpftop \
  bpftrace \
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
  iotop-c \
  nicstat \
  numactl \
  osbuild \
  osbuild-selinux \
  patch \
  powerstat \
  powertop \
  python3-pip \
  subversion \
  sysprof \
  sysstat \
  tiptop \
  trace-cmd
