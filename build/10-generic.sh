#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

dnf5 install -y \
  7zip \
  android-tools \
  ddcutil \
  evtest \
  fastfetch \
  fish \
  foo2zjs \
  gum \
  helix \
  hexedit \
  hplip \
  jetbrains-mono-fonts-all \
  just \
  lm_sensors \
  oddjob-mkhomedir \
  openssh-askpass \
  pv \
  setools-console \
  setroubleshoot-plugins \
  setroubleshoot-server \
  util-linux-script \
  ydotool \
  zenity

copr_install_isolated "fcsm/tmuxinator" tmuxinator
copr_install_isolated "che/nerd-fonts" nerd-fonts
