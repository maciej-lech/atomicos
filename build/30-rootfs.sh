#!/usr/bin/bash

set -eoux pipefail

cp -r /ctx/system/. /

glib-compile-schemas /usr/share/glib-2.0/schemas

mkdir -p /etc/flatpak/remotes.d
curl --retry 3 -fsSLo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

systemctl enable brew-setup.service
systemctl enable flatpak-add-flathub-repos.service
systemctl enable flatpak-nuke-fedora.service
systemctl enable incus-workaround.service
systemctl enable libvirt-workaround.service
# topgrade: single user-side run; bootc upgrade allowed passwordless via sudoers
systemctl --global enable topgrade.timer
systemctl --global enable udiskie.service
