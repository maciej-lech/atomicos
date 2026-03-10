#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

shopt -s nullglob

cp -r /ctx/oci/common/bluefin/. /
cp -r /ctx/oci/common/shared/. /
cp -r /ctx/oci/brew/. /

mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/ 2>/dev/null || true

find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just 2>/dev/null || true

dnf5 remove -y \
  ublue-os-just \
  ublue-os-luks \
  ublue-os-signing \
  ublue-os-udev-rules \
  ublue-os-update-services \
  yelp

copr_install_isolated "ublue-os/packages" uupd

cat > /usr/bin/ujust <<'SCRIPT'
#!/usr/bin/bash
/usr/bin/just --justfile /usr/share/ublue-os/just/00-entry.just "${@}"
SCRIPT
chmod +x /usr/bin/ujust

systemctl enable brew-setup.service
systemctl enable uupd.timer

systemctl mask flatpak-add-fedora-repos.service
systemctl mask flatpak-preinstall.service

shopt -u nullglob
