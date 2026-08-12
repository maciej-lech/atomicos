#!/usr/bin/bash

set -eoux pipefail

# shellcheck source=/dev/null
source /ctx/build/repo-helpers.sh

# libavcodec-freeworld layers the patent-encumbered codecs on top of Fedora's
# ffmpeg-free. If a fully-featured ffmpeg is ever needed, replace the Fedora
# stack instead: dnf5 swap -y ffmpeg-free ffmpeg --allowerasing
# rpmfusion's ffmpeg-libs conflicts with the libav*-free packages, so that one
# swap covers the whole set.
rpmfusion_install_isolated \
	libavcodec-freeworld \
	libva-intel-driver

dnf5 install -y \
	alsa-firmware \
	ffmpegthumbnailer \
	libheif \
	libva-utils
