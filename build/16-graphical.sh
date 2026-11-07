#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/repo-helpers.sh

dnf5 install -y \
	accountsservice \
	adw-gtk3-theme \
	adwaita-cursor-theme \
	adwaita-icon-theme \
	adwaita-icon-theme-legacy \
	cliphist \
	foot \
	gcr \
	hicolor-icon-theme \
	kf6-kimageformats \
	libadwaita \
	libappindicator-gtk3 \
	libayatana-appindicator-gtk3 \
	libportal \
	libportal-gtk4 \
	nautilus \
	oo7-daemon \
	oo7-portal \
	pam_oo7 \
	pinentry-gnome3 \
	qadwaitadecorations-qt5 \
	qt6-qtimageformats \
	qt6ct \
	sound-theme-freedesktop \
	udiskie \
	waypipe \
	wl-mirror \
	wtype \
	xdg-desktop-portal-gnome \
	xdg-desktop-portal-gtk \
	xdg-desktop-portal-wlr \
	xdg-native-messaging-proxy \
	xdg-terminal-exec \
	xdg-user-dirs

# Weak deps (alacritty, fuzzel, waybar, swaylock) duplicate what DMS provides;
# gnome-keyring would compete with oo7-daemon for org.freedesktop.secrets
dnf5 install -y --setopt=install_weak_deps=False niri

copr_install_isolated "scottames/ghostty" ghostty
terra_install_isolated satty

# renovate: datasource=github-releases depName=cjpais/handy extractVersion=^v(?<version>.+)$
HANDY_VERSION="0.10.0"
handy_rpm="Handy-${HANDY_VERSION}-1.x86_64.rpm"
handy_dir=$(mktemp -d)
curl -fsSL --retry 3 -o "$handy_dir/$handy_rpm" \
	"https://github.com/cjpais/handy/releases/download/v${HANDY_VERSION}/${handy_rpm}"
# Tauri updater signatures are base64-wrapped minisign signatures
curl -fsSL --retry 3 "https://github.com/cjpais/handy/releases/download/v${HANDY_VERSION}/${handy_rpm}.sig" |
	base64 -d >"$handy_dir/$handy_rpm.minisig"
dnf5 install -y minisign
# The signed trusted comment names the file, so an older signed release can't stand in
handy_signed=$(minisign -V -Q -p /ctx/build/keys/handy-minisign.pub \
	-m "$handy_dir/$handy_rpm" -x "$handy_dir/$handy_rpm.minisig")
if [[ "$handy_signed" != *$'\t'"file:${handy_rpm}" ]]; then
	echo "Handy signature is for '${handy_signed}', expected ${handy_rpm}" >&2
	exit 1
fi
dnf5 remove -y minisign
dnf5 install -y "$handy_dir/$handy_rpm"
rm -rf "$handy_dir"

copr_install_isolated "duxlabs/dms-git" \
	--enablerepo="coprdep:copr.fedorainfracloud.org:duxlabs:dux-repo" \
	dms dux-files dux-gop dux-greeter
# A stripped-down /etc/pam.d/greetd would shadow greetd's own stack in
# /usr/lib/pam.d and lose the keyring unlock at login (#366)
if [[ -e /etc/pam.d/greetd ]]; then
	echo "/etc/pam.d/greetd shadows greetd's /usr/lib/pam.d/greetd" >&2
	exit 1
fi
systemctl enable greetd.service

# Both nautilus and dux-files ship a D-Bus activation file for
# org.freedesktop.FileManager1; keep only the dux-files one.
rm /usr/share/dbus-1/services/org.freedesktop.FileManager1.service

if rpm -q gnome-keyring; then
	echo "gnome-keyring is installed and would compete with oo7-daemon" >&2
	exit 1
fi
