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

echo "::endgroup::"

echo "::group:: Remove unwanted base packages"

dnf5 remove -y \
  ublue-os-just \
  ublue-os-luks \
  ublue-os-signing \
  ublue-os-udev-rules \
  ublue-os-update-services \
  yelp

echo "::endgroup::"

echo "::group:: Install Packages"

# Install standard packages
dnf5 install -y \
  7zip \
  android-tools \
  borgbackup \
  cascadia-code-fonts \
  davfs2 \
  ddcutil \
  dhcpcd \
  evtest \
  fastfetch \
  firewall-config \
  fish \
  foo2zjs \
  fsverity-utils \
  fuse-encfs \
  fzf \
  git-credential-libsecret \
  git-lfs \
  git-subtree \
  git-svn \
  glow \
  gnome-shell-extension-gsconnect \
  gnome-tweaks \
  gum \
  helix \
  hexedit \
  hplip \
  input-remapper \
  iwd \
  jetbrains-mono-fonts-all \
  just \
  libxcrypt-compat \
  lm_sensors \
  mkisofs \
  NetworkManager-team \
  niri \
  numactl \
  oddjob-mkhomedir \
  opendyslexic-fonts \
  openssh-askpass \
  podman-compose \
  podman-machine \
  podman-tui \
  powerstat \
  powertop \
  pv \
  python3-pip \
  python3-rpm \
  python3-systemd \
  qt6ct \
  rclone \
  restic \
  schily-libs \
  setools-console \
  setroubleshoot-plugins \
  setroubleshoot-server \
  socat \
  subversion \
  usbip \
  util-linux-script \
  waypipe \
  xdg-terminal-exec \
  ydotool \
  zenity

# LUKS/Clevis
dnf5 install -y \
  clevis \
  clevis-luks \
  clevis-pin-tpm2

# Filesystem tools
dnf5 install -y \
  bcache-tools \
  cryfs \
  device-mapper-multipath \
  libblockdev-btrfs \
  libblockdev-lvm \
  udisks2-btrfs \
  udisks2-iscsi \
  udisks2-lvm2

# Dev tools
dnf5 install -y \
  ccache \
  debugedit \
  dwz \
  elfutils \
  flatpak-builder \
  gdb-minimal \
  patch

# osbuild
dnf5 install -y \
  osbuild \
  osbuild-selinux

# Virtualization
dnf5 install -y \
  edk2-ovmf \
  incus \
  incus-agent \
  libvirt \
  libvirt-dbus \
  libvirt-nss \
  lxc \
  qemu \
  qemu-user-binfmt \
  qemu-user-static \
  swtpm \
  swtpm-tools \
  udica \
  virt-install \
  virt-manager \
  virt-v2v \
  virt-viewer

# System profiling
dnf5 install -y \
  bcc \
  bcc-tools \
  bpftop \
  bpftrace \
  iotop-c \
  nicstat \
  sysprof \
  sysstat \
  systemtap-client \
  systemtap-devel \
  systemtap-runtime \
  tiptop \
  trace-cmd

# Samba (without AD/sssd)
dnf5 install -y \
  samba \
  samba-common-tools \
  samba-dcerpc \
  samba-ldb-ldap-modules \
  samba-libs \
  samba-winbind \
  samba-winbind-clients \
  samba-winbind-modules

# Install COPR packages (isolated)
copr_install_isolated "scottames/ghostty" ghostty
copr_install_isolated "fcsm/tmuxinator" tmuxinator
copr_install_isolated "che/nerd-fonts" nerd-fonts
copr_install_isolated "ublue-os/packages" uupd

# avengemedia/dms has a dependency repo (danklinux) that must also be enabled
dnf5 -y copr enable avengemedia/dms
dnf5 -y copr disable avengemedia/dms
dnf5 -y install \
  --enablerepo="copr:copr.fedorainfracloud.org:avengemedia:dms" \
  --enablerepo="coprdep:copr.fedorainfracloud.org:avengemedia:danklinux" \
  cliphist dms dms-greeter

# Install Docker CE from official repo
dnf5 config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
dnf5 -y install --enablerepo=docker-ce-stable \
  containerd.io \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  docker-model-plugin

# Install tailscale from official repo
dnf5 config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf5 install -y tailscale
dnf5 config-manager setopt tailscale-stable.enabled=0

echo "::endgroup::"

# Cleanup
dnf5 clean all

echo "::group:: System Configuration"

# Install libvirt SELinux workaround service
cat > /usr/lib/systemd/system/libvirt-workaround.service <<'UNIT'
[Unit]
Description=Workaround to relabel libvirt files and directories
ConditionPathIsDirectory=/var/lib/libvirt/
After=local-fs.target

[Service]
Type=oneshot
ExecStart=-/usr/sbin/restorecon -R /var/log/libvirt/
ExecStart=-/usr/sbin/restorecon -R /var/lib/libvirt/
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT

# Install swtpm SELinux workaround service
cat > /usr/lib/systemd/system/swtpm-workaround.service <<'UNIT'
[Unit]
Description=Workaround swtpm not having the correct label
ConditionFileIsExecutable=/usr/bin/swtpm
After=local-fs.target

[Service]
Type=oneshot
ExecStartPre=/usr/bin/bash -c "[ -x /usr/local/bin/overrides/swtpm ] || /usr/bin/cp /usr/bin/swtpm /usr/local/bin/overrides/swtpm"
ExecStartPre=/usr/bin/mount --bind /usr/local/bin/overrides/swtpm /usr/bin/swtpm
ExecStart=/usr/sbin/restorecon /usr/bin/swtpm
ExecStop=/usr/bin/umount /usr/bin/swtpm
ExecStop=/usr/bin/rm /usr/local/bin/overrides/swtpm
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT

# Install groups setup script (adds wheel users to docker, incus-admin, libvirt)
cat > /usr/bin/atomicos-groups <<'SCRIPT'
#!/usr/bin/env bash
GROUP_SETUP_VER=1
GROUP_SETUP_VER_FILE="/etc/atomicos/groups"
GROUP_SETUP_VER_RAN=$(cat "$GROUP_SETUP_VER_FILE" 2>/dev/null)

mkdir -p /etc/atomicos

if [[ -f $GROUP_SETUP_VER_FILE && "$GROUP_SETUP_VER" = "$GROUP_SETUP_VER_RAN" ]]; then
  echo "Group setup has already run. Exiting..."
  exit 0
fi

append_group() {
  local group_name="$1"
  if ! grep -q "^$group_name:" /etc/group; then
    echo "Appending $group_name to /etc/group"
    grep "^$group_name:" /usr/lib/group | tee -a /etc/group >/dev/null
  fi
}

append_group docker
append_group incus-admin
append_group libvirt

wheelarray=($(getent group wheel | cut -d ":" -f 4 | tr ',' '\n'))
for user in $wheelarray; do
  usermod -aG docker "$user"
  usermod -aG incus-admin "$user"
  usermod -aG libvirt "$user"
done

echo "Writing state file"
echo "$GROUP_SETUP_VER" > "$GROUP_SETUP_VER_FILE"
SCRIPT
chmod +x /usr/bin/atomicos-groups

cat > /usr/lib/systemd/system/atomicos-groups.service <<'UNIT'
[Unit]
Description=Add wheel members to docker, incus-admin, and libvirt groups

[Service]
Type=oneshot
ExecStart=/usr/bin/atomicos-groups
Restart=on-failure
RestartSec=30
StartLimitInterval=0

[Install]
WantedBy=default.target
UNIT

# Enable system services
systemctl enable podman.socket
systemctl enable docker.socket
systemctl enable tailscaled.service
systemctl enable brew-setup.service
systemctl enable dconf-update.service
systemctl enable ublue-system-setup.service
systemctl enable input-remapper.service
systemctl enable uupd.timer
systemctl enable swtpm-workaround.service
systemctl enable libvirt-workaround.service
systemctl enable atomicos-groups.service

# Enable user services globally
systemctl --global enable ublue-user-setup.service

# Disable Fedora flatpak repos (we use Flathub)
systemctl mask flatpak-add-fedora-repos.service
systemctl mask flatpak-preinstall.service

echo "::endgroup::"

echo "::group:: Fix bootc lint warnings"

# Clean runtime-only directories left by dnf5 and selinux-policy
rm -rf /run/dnf /run/selinux-policy

# Clean dnf repo state from /var
rm -rf /var/lib/dnf

# Add sysusers.d entries for users/groups without them
cat > /usr/lib/sysusers.d/dms-greeter.conf <<'SYSUSERS'
u greeter 962 "System Greeter" /var/lib/greeter /bin/bash
SYSUSERS

cat > /usr/lib/sysusers.d/docker.conf <<'SYSUSERS'
g docker -
SYSUSERS

# Add tmpfiles.d entries for greetd state in /var
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
