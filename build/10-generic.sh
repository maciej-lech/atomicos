#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

dnf5 install -y \
  7zip \
  android-tools \
  bolt \
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
  jetbrains-mono-fonts-all \
  just \
  kernel-tools \
  lm_sensors \
  oddjob-mkhomedir \
  openssh-askpass \
  pam-u2f \
  pamu2fcfg \
  pv \
  setools-console \
  setroubleshoot-plugins \
  setroubleshoot-server \
  smartmontools \
  switcheroo-control \
  tmux \
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
