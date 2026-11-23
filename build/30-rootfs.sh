#!/usr/bin/bash

set -eoux pipefail

cp -r /ctx/system/. /

glib-compile-schemas /usr/share/glib-2.0/schemas

systemctl enable brew-setup.service
systemctl enable flatpak-add-flathub-repos.service
systemctl enable flatpak-nuke-fedora.service
systemctl enable fwupd-refresh.timer
systemctl enable incus-workaround.service
systemctl enable libvirt-workaround.service
systemctl enable bootc-update-ca-trust.service
systemctl enable bootc-update-crypto-policies.service
systemctl --global enable dfiles.service
systemctl --global enable gcr-ssh-agent.socket
# dux-search ships no preset; DMS launcher file search needs the index
systemctl --global enable dsearch.service
# topgrade: single user-side run; bootc upgrade allowed passwordless via sudoers
systemctl --global enable topgrade.timer
systemctl --global enable udiskie.service
