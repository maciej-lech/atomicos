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
	switcheroo-control \
	sysprof \
	sysstat \
	tiptop \
	tmux \
	trace-cmd \
	tuned \
	tuned-ppd \
	util-linux-script \
	wl-clipboard \
	ydotool \
	yubikey-manager \
	zenity \
	zoxide

copr_install_isolated "che/nerd-fonts" nerd-fonts
copr_install_isolated "fcsm/tmuxinator" tmuxinator
copr_install_isolated "lilay/topgrade" topgrade
terra_install_isolated --setopt=install_weak_deps=False yazi
