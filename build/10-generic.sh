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

# Terra ships the Nerd Font symbols fontconfig rule but does not enable it.
NERD_SYMBOLS_CONF=/usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly/10-nerd-font-symbols.conf
test -f "$NERD_SYMBOLS_CONF"
ln -s "$NERD_SYMBOLS_CONF" /etc/fonts/conf.d/10-nerd-font-symbols.conf
