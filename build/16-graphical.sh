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
	qt6ct \
	sound-theme-freedesktop \
	udiskie \
	wl-mirror \
	wtype \
	xdg-desktop-portal-gnome \
	xdg-desktop-portal-gtk \
	xdg-desktop-portal-wlr \
	xdg-terminal-exec \
	xdg-user-dirs

copr_install_isolated "scottames/ghostty" ghostty
terra_install_isolated satty

# renovate: datasource=github-releases depName=cjpais/handy extractVersion=^v(?<version>.+)$
HANDY_VERSION="0.9.6"
dnf5 install -y \
	"https://github.com/cjpais/handy/releases/download/v${HANDY_VERSION}/Handy-${HANDY_VERSION}-1.x86_64.rpm"

# niri Recommends gnome-keyring, which would compete with oo7-daemon for
# org.freedesktop.secrets
copr_install_isolated "avengemedia/dms-git" \
	--enablerepo="coprdep:copr.fedorainfracloud.org:avengemedia:danklinux" \
	--exclude=gnome-keyring \
	cliphist dms dms-greeter niri waypipe
# greetd ships its PAM stack in /usr/lib/pam.d, so dms-greeter's %post finds no
# /etc/pam.d/greetd and writes a stripped-down one that shadows it, losing the
# keyring unlock at login
rm -f /etc/pam.d/greetd
systemctl enable greetd.service
