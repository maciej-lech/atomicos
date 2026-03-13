#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

dnf5 install -y \
  7zip \
  android-tools \
  bcc \
  bcc-tools \
  bolt \
  bpftop \
  bpftrace \
  colord-gtk4 \
  cups-pk-helper \
  ddcutil \
  evtest \
  fastfetch \
  fish \
  foo2zjs \
  fprintd \
  fprintd-pam \
  google-noto-sans-cjk-fonts \
  gum \
  hdparm \
  helix \
  hexedit \
  hplip \
  htop \
  iotop-c \
  jetbrains-mono-fonts-all \
  just \
  kernel-tools \
  lm_sensors \
  nicstat \
  numactl \
  oddjob-mkhomedir \
  openssh-askpass \
  pam-u2f \
  pamu2fcfg \
  powerstat \
  powertop \
  pv \
  setools-console \
  setroubleshoot-plugins \
  setroubleshoot-server \
  smartmontools \
  switcheroo-control \
  sysprof \
  sysstat \
  tiptop \
  tmux \
  trace-cmd \
  tuned \
  tuned-ppd \
  util-linux-script \
  wl-clipboard \
  ydotool \
  yubikey-manager \
  zenity

copr_install_isolated "fcsm/tmuxinator" tmuxinator
copr_install_isolated "che/nerd-fonts" nerd-fonts
copr_install_isolated "ublue-os/packages" uupd

systemctl enable uupd.timer
