#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

dnf5 install -y \
  7zip \
  android-tools \
  bolt \
  colord-gtk4 \
  ddcutil \
  evtest \
  fastfetch \
  fish \
  foo2zjs \
  fprintd \
  fprintd-pam \
  gum \
  hdparm \
  helix \
  hexedit \
  hplip \
  iio-sensor-proxy \
  jetbrains-mono-fonts-all \
  just \
  kernel-tools \
  lm_sensors \
  oddjob-mkhomedir \
  openssh-askpass \
  pv \
  setools-console \
  setroubleshoot-plugins \
  setroubleshoot-server \
  switcheroo-control \
  tuned \
  tuned-ppd \
  util-linux-script \
  ydotool \
  zenity

copr_install_isolated "fcsm/tmuxinator" tmuxinator
copr_install_isolated "che/nerd-fonts" nerd-fonts
