#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

dnf5 remove -y \
  ublue-os-just \
  ublue-os-luks \
  ublue-os-signing \
  ublue-os-udev-rules \
  ublue-os-update-services

copr_install_isolated "ublue-os/packages" uupd

systemctl enable uupd.timer
