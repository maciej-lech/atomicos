#!/usr/bin/bash

set -eoux pipefail

cp -r /ctx/system/. /

glib-compile-schemas /usr/share/glib-2.0/schemas

systemctl enable brew-setup.service
systemctl enable flatpak-add-flathub-repos.service
systemctl enable flatpak-nuke-fedora.service
systemctl enable incus-workaround.service
systemctl enable libvirt-workaround.service
# topgrade: single user-side run; bootc upgrade allowed passwordless via sudoers
systemctl mask topgrade.service topgrade.timer
systemctl --global enable topgrade.timer
systemctl --global enable udiskie.service
