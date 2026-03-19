#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

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
	libportal \
	libportal-gtk4 \
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

# Can't use copr_install_isolated because we need to enable the danklinux copr dependency
dnf5 -y copr enable avengemedia/dms-git
dnf5 -y copr disable avengemedia/dms-git
dnf5 -y install \
	--enablerepo="copr:copr.fedorainfracloud.org:avengemedia:dms-git" \
	--enablerepo="coprdep:copr.fedorainfracloud.org:avengemedia:danklinux" \
	cliphist dms dms-greeter niri waypipe

systemctl enable greetd.service
