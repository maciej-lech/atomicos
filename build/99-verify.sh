#!/usr/bin/bash

set -eoux pipefail

# Checks the finished image and changes nothing; every check runs and all
# failures are reported before the build fails
FAILED=0
fail() {
	echo "Build failed: $*" >&2
	FAILED=1
}

# Validate no third-party repos are left enabled; ask dnf so repos enabled by
# default (no enabled= key) are caught too
ALLOWED_REPOS=(fedora updates fedora-cisco-openh264 updates-archive)
if ! enabled_json=$(dnf5 -q repo list --enabled --json); then
	fail "could not list enabled repos"
elif ! enabled_ids=$(jq -r '.[].id' <<<"$enabled_json"); then
	fail "could not parse enabled repos"
else
	mapfile -t enabled_repos <<<"$enabled_ids"
	repos_ok=1
	for repo in "${enabled_repos[@]}"; do
		[[ -n "$repo" ]] || continue
		if [[ " ${ALLOWED_REPOS[*]} " != *" $repo "* ]]; then
			echo "ERROR: Enabled repo found: $repo" >&2
			repos_ok=0
		fi
	done
	((repos_ok)) || fail "third-party repos left enabled"
fi

# /home is a symlink to /var/home; 90-cleanup.sh restores the subs_dist line
# that labels /var/home like /home
SUBS_DIST=/etc/selinux/targeted/contexts/files/file_contexts.subs_dist
if ! grep -qE '^/home[[:space:]]+/var/home$' "$SUBS_DIST"; then
	fail "$SUBS_DIST lacks '/home /var/home'"
fi

# Hosts keep their own /etc/passwd across updates, so every account the image
# adds needs a pinned ID, and no ID may name two accounts across /etc (image
# defaults) and /usr/lib (base image, read through nss-altfiles)
SYSUSERS_PINS=/usr/lib/sysusers.d/00-atomicos-ids.conf
check_ids() {
	awk -v db="$1" -v types="$2" -v pins="$SYSUSERS_PINS" '
		FNR == 1 { file++ }
		file == 1 {
			if ($1 ~ types) pinned[$2] = $3
			next
		}
		{
			split($0, f, ":")
			name = f[1]
			id = f[3]
			src = (file == 2 ? "/usr/lib/" : "/etc/") db
			if (name in id_of) {
				if (id_of[name] != id) {
					printf "%s: %s is %s in %s and %s in %s\n", db, name, id_of[name], src_of[name], id, src
					bad = 1
				}
				next
			}
			if (id in name_of) {
				printf "%s: ID %s is %s in %s and %s in %s\n", db, id, name_of[id], src_of[name_of[id]], name, src
				bad = 1
			}
			id_of[name] = id
			src_of[name] = src
			name_of[id] = name
			if (file == 3 && id != 0) {
				if (!(name in pinned)) {
					printf "%s: %s (%s) is not pinned in %s\n", db, name, id, pins
					bad = 1
				} else if (pinned[name] != id) {
					printf "%s: %s is %s, pinned to %s\n", db, name, id, pinned[name]
					bad = 1
				}
			}
		}
		END { exit bad }
	' "$SYSUSERS_PINS" FS=: "/usr/lib/$1" "/etc/$1"
}
IDS_OK=1
check_ids passwd '^u!?$' || IDS_OK=0
check_ids group '^(u!?|g)$' || IDS_OK=0
if ((! IDS_OK)); then
	fail "account IDs drift or collide; pin them in $SYSUSERS_PINS"
fi

# systemd-sysusers runs on every boot (ostree keeps /usr at mtime 0, so
# ConditionNeedsUpdate=/etc always holds) and logs each package line that
# conflicts with a pin; 90-cleanup.sh writes the pinned IDs into those lines
if ! sysusers_out=$(systemd-sysusers --dry-run 2>&1); then
	echo "$sysusers_out"
	fail "systemd-sysusers --dry-run failed"
elif grep -F 'Conflict with earlier configuration' <<<"$sysusers_out"; then
	fail "sysusers.d lines conflict with $SYSUSERS_PINS; match their fields"
fi

# Our rpm-ostree polkit rule overwrites Fedora's by filename; fail if a renamed
# upstream copy would still grant passwordless package layering
rpmostree_grants=$(grep -rls 'rpmostree1.install-uninstall-packages' /usr/share/polkit-1/rules.d /etc/polkit-1/rules.d || true)
if [[ -n "$rpmostree_grants" ]]; then
	fail "unexpected rpm-ostree polkit grant in: $rpmostree_grants"
fi

# ISO installs enforce /etc/containers/policy.json for updates. A policy that does
# not parse or names a missing key rejects every pull; a missing image scope falls
# through to the "" catch-all and verifies nothing.
policy=/etc/containers/policy.json
if ! policy_keys=$(jq -r '.. | objects | (.keyPath // empty), (.keyPaths // [])[], (.rekorPublicKeyPath // empty)' "$policy"); then
	fail "invalid container trust policy: $policy"
else
	while read -r key; do
		[[ -n "$key" ]] || continue
		if [[ ! -s "$key" ]]; then
			fail "container trust policy key missing or empty: $key"
		fi
	done <<<"$policy_keys"
fi
if ! jq -e '.transports.docker["ghcr.io/maciej-lech"] | any(.type == "sigstoreSigned")' "$policy" >/dev/null; then
	fail "no sigstoreSigned scope for ghcr.io/maciej-lech in $policy"
fi
if ! grep -q 'use-sigstore-attachments: true' /etc/containers/registries.d/maciej-lech.yaml; then
	fail "sigstore attachments not enabled for ghcr.io/maciej-lech in registries.d"
fi

# A stripped-down /etc/pam.d/greetd would shadow greetd's own stack in
# /usr/lib/pam.d and lose the keyring unlock at login (#366)
if [[ -e /etc/pam.d/greetd ]]; then
	fail "/etc/pam.d/greetd shadows greetd's /usr/lib/pam.d/greetd"
fi

if rpm -q gnome-keyring; then
	fail "gnome-keyring is installed and would compete with oo7-daemon"
fi

# Eager binding surfaces missing symbols from mixed libav* versions
if ! LD_BIND_NOW=1 ffmpeg -hide_banner -decoders | awk '$2 == "hevc" { print; found = 1 } END { exit !found }'; then
	fail "ffmpeg has no working hevc decoder"
fi

if ((FAILED)); then
	exit 1
fi
