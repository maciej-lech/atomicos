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

# ISO installs enforce /etc/containers/policy.json for updates. A policy that does
# not parse or names a missing key rejects every pull; a missing image scope falls
# through to the "" catch-all and verifies nothing.
policy=/etc/containers/policy.json
if ! policy_keys=$(jq -r '.. | objects | (.keyPath // empty), (.keyPaths // [])[], (.rekorPublicKeyPath // empty)' "$policy"); then
	echo "Invalid container trust policy: $policy" >&2
	exit 1
fi
while read -r key; do
	[[ -n "$key" ]] || continue
	if [[ ! -s "$key" ]]; then
		echo "Container trust policy key missing or empty: $key" >&2
		exit 1
	fi
done <<<"$policy_keys"
if ! jq -e '.transports.docker["ghcr.io/maciej-lech"] | any(.type == "sigstoreSigned")' "$policy" >/dev/null; then
	echo "No sigstoreSigned scope for ghcr.io/maciej-lech in $policy" >&2
	exit 1
fi
if ! grep -q 'use-sigstore-attachments: true' /etc/containers/registries.d/maciej-lech.yaml; then
	echo "Sigstore attachments not enabled for ghcr.io/maciej-lech in registries.d" >&2
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
