#!/usr/bin/bash

set -eoux pipefail

cp -r /ctx/system/. /

systemctl enable brew-setup.service
systemctl enable flatpak-add-flathub-repos.service
systemctl enable flatpak-nuke-fedora.service
systemctl enable incus-workaround.service
systemctl enable libvirt-workaround.service
systemctl enable swtpm-workaround.service
