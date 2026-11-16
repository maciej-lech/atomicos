#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/repo-helpers.sh

dnf5 install -y \
	7zip \
	android-tools \
	bcc \
	bcc-tools \
	bolt \
	bpftop \
	bpftrace \
	brightnessctl \
	btop \
	colord-gtk4 \
	cups-pk-helper \
	ddcutil \
	dracut-network \
	dracut-squash \
	evtest \
	fastfetch \
	fd-find \
	fish \
	foo2zjs \
	fprintd \
	fprintd-pam \
	fzf \
	google-noto-sans-cjk-fonts \
	gum \
	hdparm \
	helix \
	hexedit \
	hplip \
	htop \
	iotop-c \
	irqbalance \
	jetbrains-mono-fonts-all \
	just \
	kernel-tools \
	lm_sensors \
	lshw \
	nicstat \
	numactl \
	oddjob-mkhomedir \
	openssh-askpass \
	pam-u2f \
	pamu2fcfg \
	powerstat \
	powertop \
	pv \
	ripgrep \
	setools-console \
	setroubleshoot-plugins \
	setroubleshoot-server \
	smartmontools \
	solaar-udev \
	switcheroo-control \
	sysprof \
	sysstat \
	tiptop \
	trace-cmd \
	tuned \
	tuned-ppd \
	util-linux-script \
	vulkan-tools \
	wl-clipboard \
	ydotool \
	yubikey-manager \
	zenity \
	zoxide

terra_install_isolated nerdfontssymbolsonly-nerd-fonts topgrade

# Terra's /etc/fonts/conf.d link for the Nerd Font symbols rule is broken (relative
# "../usr/share/..." resolves under /etc/fonts), so point it at the real file.
NERD_SYMBOLS_CONF=/usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf
test -f "$NERD_SYMBOLS_CONF"
ln -sfn "$NERD_SYMBOLS_CONF" /etc/fonts/conf.d/10-nerd-font-symbols.conf
