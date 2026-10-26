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
	foot \
	gcr \
	gnome-keyring \
	gnome-keyring-pam \
	hicolor-icon-theme \
	kf6-kimageformats \
	libadwaita \
	libappindicator-gtk3 \
	libayatana-appindicator-gtk3 \
	libportal \
	libportal-gtk4 \
	nautilus \
	pinentry-gnome3 \
	qadwaitadecorations-qt5 \
	qt6ct \
	sound-theme-freedesktop \
	udiskie \
	wl-mirror \
	wtype \
	xdg-desktop-portal-gnome \
	xdg-desktop-portal-gtk \
	xdg-desktop-portal-wlr \
	xdg-native-messaging-proxy \
	xdg-terminal-exec \
	xdg-user-dirs

copr_install_isolated "scottames/ghostty" ghostty
terra_install_isolated satty

# renovate: datasource=github-releases depName=cjpais/handy extractVersion=^v(?<version>.+)$
HANDY_VERSION="0.9.8"
dnf5 install -y \
	"https://github.com/cjpais/handy/releases/download/v${HANDY_VERSION}/Handy-${HANDY_VERSION}-1.x86_64.rpm"

copr_install_isolated "avengemedia/dms-git" \
	--enablerepo="coprdep:copr.fedorainfracloud.org:avengemedia:danklinux" \
	cliphist dms dms-greeter dux-files niri waypipe
systemctl enable greetd.service

# Both nautilus and dux-files ship a D-Bus activation file for
# org.freedesktop.FileManager1; keep only the dux-files one.
rm /usr/share/dbus-1/services/org.freedesktop.FileManager1.service
