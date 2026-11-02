#!/usr/bin/bash

set -eoux pipefail

cp -r /ctx/system/. /

# Our rpm-ostree polkit rule overwrites Fedora's by filename; fail if a renamed
# upstream copy would still grant passwordless package layering
rpmostree_grants=$(grep -rls 'rpmostree1.install-uninstall-packages' /usr/share/polkit-1/rules.d /etc/polkit-1/rules.d || true)
if [[ -n "$rpmostree_grants" ]]; then
	echo "Unexpected rpm-ostree polkit grant in: $rpmostree_grants" >&2
	exit 1
fi

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
# topgrade: single user-side run; bootc upgrade allowed passwordless via sudoers
systemctl --global enable topgrade.timer
systemctl --global enable udiskie.service
