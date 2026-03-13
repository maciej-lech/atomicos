#!/usr/bin/bash

set -eoux pipefail

systemctl disable rpm-ostreed-automatic.timer
systemctl mask flatpak-add-fedora-repos.service

# Disable repos inherited from base image
for repo in /etc/yum.repos.d/_copr*.repo; do
	[[ -f "$repo" ]] && sed -i 's/enabled=1/enabled=0/g' "$repo"
done

dnf5 clean all

rm -rf /boot && mkdir -p /boot
rm -rf /tmp && mkdir -p /tmp
rm -rf /run && mkdir -p /run
rm -rf /var/* && mkdir /var/tmp

# Validate no repos are left enabled
VALIDATION_FAILED=0

for repo in /etc/yum.repos.d/*.repo; do
	[[ -f "$repo" ]] || continue
	basename_repo=$(basename "$repo")
	[[ "$basename_repo" == fedora.repo ]] && continue
	[[ "$basename_repo" == fedora-updates*.repo ]] && continue
	[[ "$basename_repo" == fedora-cisco-openh264.repo ]] && continue
	if grep -q "^enabled=1" "$repo" 2>/dev/null; then
		echo "ERROR: Enabled repo found: $(basename "$repo")"
		grep -B5 "^enabled=1" "$repo"
		VALIDATION_FAILED=1
	fi
done

if [[ $VALIDATION_FAILED -eq 1 ]]; then
	echo "Build failed: third-party repos left enabled"
	exit 1
fi

# Symlink /usr/local and /opt to /var so they are writable on bootc
rm -rfv /opt /usr/local
ln -s /var/usrlocal /usr/local
ln -s /var/opt /opt
