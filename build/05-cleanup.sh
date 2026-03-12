#!/usr/bin/bash

set -eoux pipefail

dnf5 remove -y \
  ublue-os-just \
  ublue-os-luks \
  ublue-os-signing \
  ublue-os-udev-rules \
  ublue-os-update-services \
  yelp
