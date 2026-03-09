#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

# Packages
dnf5 install -y \
  7zip \
  android-tools \
  bcache-tools \
  bcc \
  bcc-tools \
  bpftop \
  bpftrace \
  cascadia-code-fonts \
  ccache \
  clevis \
  clevis-luks \
  clevis-pin-tpm2 \
  cryfs \
  davfs2 \
  ddcutil \
  debugedit \
  device-mapper-multipath \
  dhcpcd \
  dwz \
  edk2-ovmf \
  elfutils \
  evtest \
  fastfetch \
  firewall-config \
  fish \
  flatpak-builder \
  foo2zjs \
  fsverity-utils \
  fuse-encfs \
  gdb-minimal \
  git-credential-libsecret \
  git-lfs \
  git-subtree \
  git-svn \
  glow \
  gnome-shell-extension-gsconnect \
  gnome-tweaks \
  gum \
  helix \
  hexedit \
  hplip \
  incus \
  incus-agent \
  iotop-c \
  iwd \
  jetbrains-mono-fonts-all \
  just \
  libblockdev-btrfs \
  libblockdev-lvm \
  libvirt \
  libvirt-dbus \
  libvirt-nss \
  libxcrypt-compat \
  lm_sensors \
  lxc \
  mkisofs \
  NetworkManager-team \
  nicstat \
  numactl \
  oddjob-mkhomedir \
  opendyslexic-fonts \
  openssh-askpass \
  osbuild \
  osbuild-selinux \
  patch \
  podman-compose \
  podman-machine \
  podman-tui \
  powerstat \
  powertop \
  pv \
  python3-pip \
  python3-rpm \
  python3-systemd \
  qemu \
  qemu-user-binfmt \
  qemu-user-static \
  qt6ct \
  samba \
  samba-common-tools \
  samba-dcerpc \
  samba-ldb-ldap-modules \
  samba-libs \
  samba-winbind \
  samba-winbind-clients \
  samba-winbind-modules \
  schily-libs \
  setools-console \
  setroubleshoot-plugins \
  setroubleshoot-server \
  socat \
  subversion \
  swtpm \
  swtpm-tools \
  sysprof \
  sysstat \
  systemtap-client \
  systemtap-devel \
  systemtap-runtime \
  tiptop \
  trace-cmd \
  udica \
  udisks2-btrfs \
  udisks2-iscsi \
  udisks2-lvm2 \
  usbip \
  util-linux-script \
  virt-install \
  virt-manager \
  virt-v2v \
  virt-viewer \
  waypipe \
  xdg-terminal-exec \
  ydotool \
  zenity

# COPR packages
copr_install_isolated "scottames/ghostty" ghostty
copr_install_isolated "fcsm/tmuxinator" tmuxinator
copr_install_isolated "che/nerd-fonts" nerd-fonts

# Services
systemctl enable podman.socket
