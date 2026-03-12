#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

dnf5 install -y \
  qt6ct \
  xdg-terminal-exec

copr_install_isolated "scottames/ghostty" ghostty

dnf5 -y copr enable avengemedia/dms
dnf5 -y copr disable avengemedia/dms
dnf5 -y install \
  --enablerepo="copr:copr.fedorainfracloud.org:avengemedia:dms" \
  --enablerepo="coprdep:copr.fedorainfracloud.org:avengemedia:danklinux" \
  cliphist dms dms-greeter niri waypipe

systemctl disable gdm.service
systemctl enable greetd.service

