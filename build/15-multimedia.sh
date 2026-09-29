#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/repo-helpers.sh

# Replace Fedora's whole ffmpeg-free stack rather than layering
# libavcodec-freeworld on top of it: freeworld has to match libav*-free exactly,
# and when RPM Fusion and Fedora ship updates out of step dnf silently falls
# back to a mismatched pair that breaks at runtime. ffmpeg-libs conflicts with
# the libav*-free packages, hence --allowerasing.
rpmfusion_install_isolated \
	--allowerasing \
	ffmpeg \
	libva-intel-driver

dnf5 install -y \
	alsa-firmware \
	ffmpegthumbnailer \
	libheif \
	libva-utils

# Eager binding surfaces missing symbols from mixed libav* versions
LD_BIND_NOW=1 ffmpeg -hide_banner -decoders | awk '$2 == "hevc" { print; found = 1 } END { exit !found }'
