#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Main Build Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

# Enable nullglob for all glob operations to prevent failures on empty matches
shopt -s nullglob

echo "::group:: Copy Bluefin Config from Common"

# Copy configuration from @projectbluefin/common OCI layer
# Use /. suffix to copy directory contents, not the directory itself
cp -r /ctx/oci/common/bluefin/. /
cp -r /ctx/oci/common/shared/. /

# Copy Homebrew integration (tarball, systemd services, shell profile)
cp -r /ctx/oci/brew/. /

echo "::endgroup::"

echo "::group:: Copy Custom Files"

# Copy Brewfiles to standard location
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/ 2>/dev/null || true

# Consolidate Just Files
find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just 2>/dev/null || true

# Copy Flatpak preinstall files
mkdir -p /etc/flatpak/preinstall.d/
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/ 2>/dev/null || true

echo "::endgroup::"

echo "::group:: Install Packages"

# Install standard packages
dnf5 install -y \
  fsverity-utils \
  helix \
  qt6ct \
  socat \
  niri

# Install COPR packages (isolated)
copr_install_isolated "scottames/ghostty" ghostty
copr_install_isolated "fcsm/tmuxinator" tmuxinator
# avengemedia/dms has a dependency repo (danklinux) that must also be enabled
dnf5 -y copr enable avengemedia/dms
dnf5 -y copr disable avengemedia/dms
dnf5 -y install \
  --enablerepo="copr:copr.fedorainfracloud.org:avengemedia:dms" \
  --enablerepo="coprdep:copr.fedorainfracloud.org:avengemedia:danklinux" \
  cliphist dms-greeter

echo "::endgroup::"

# Cleanup
dnf5 clean all

echo "::endgroup::"

echo "::group:: System Configuration"

# Enable systemd services
systemctl enable podman.socket

echo "::endgroup::"

echo "::group:: Fix bootc lint warnings"

# Clean runtime-only directories left by dnf5 and selinux-policy
rm -rf /run/dnf /run/selinux-policy

# Clean dnf repo state from /var
rm -rf /var/lib/dnf

# Add sysusers.d entry for greeter user created by dms-greeter
cat > /usr/lib/sysusers.d/dms-greeter.conf <<'SYSUSERS'
u greeter 962 "System Greeter" /var/lib/greeter /bin/bash
SYSUSERS

# Add tmpfiles.d entries for greetd and dnf state in /var
cat > /usr/lib/tmpfiles.d/dms-greeter.conf <<'TMPFILES'
d /var/lib/greetd/.config 0755 greetd greetd - -
d /var/lib/greetd/.config/systemd 0755 greetd greetd - -
d /var/lib/greetd/.config/systemd/user 0755 greetd greetd - -
L /var/lib/greetd/.config/systemd/user/xdg-desktop-portal.service - - - - /dev/null
TMPFILES

echo "::endgroup::"

# Restore default glob behavior
shopt -u nullglob

echo "Custom build complete!"
