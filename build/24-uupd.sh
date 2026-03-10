#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

copr_install_isolated "ublue-os/packages" uupd

systemctl enable uupd.timer
