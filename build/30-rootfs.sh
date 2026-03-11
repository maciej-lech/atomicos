#!/usr/bin/bash

set -eoux pipefail

cp -r /ctx/system/. /

systemctl enable libvirt-workaround.service
systemctl enable swtpm-workaround.service
