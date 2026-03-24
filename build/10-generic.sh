#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

dnf5 install -y \
	7zip \
	android-tools \
	bcc \
	bcc-tools \
	bolt \
	bpftop \
	bpftrace \
	brightnessctl \
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

dnf5 -y copr enable lihaohong/yazi
dnf5 -y copr disable lihaohong/yazi
dnf5 -y install --setopt=install_weak_deps=False \
	--enablerepo="copr:copr.fedorainfracloud.org:lihaohong:yazi" \
	yazi

copr_install_isolated "fcsm/tmuxinator" tmuxinator
copr_install_isolated "che/nerd-fonts" nerd-fonts
copr_install_isolated "lilay/topgrade" topgrade
