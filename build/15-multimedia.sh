#!/usr/bin/bash

set -eoux pipefail

dnf5 config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo
dnf5 config-manager setopt fedora-multimedia.priority=90

dnf5 swap -y ffmpeg-free ffmpeg --allowerasing
dnf5 swap -y libavcodec-free libavcodec --allowerasing
dnf5 swap -y libavdevice-free libavdevice --allowerasing
dnf5 swap -y libavfilter-free libavfilter --allowerasing
dnf5 swap -y libavformat-free libavformat --allowerasing
dnf5 swap -y libavutil-free libavutil --allowerasing
dnf5 swap -y libpostproc-free libpostproc --allowerasing
dnf5 swap -y libswresample-free libswresample --allowerasing
dnf5 swap -y libswscale-free libswscale --allowerasing

dnf5 install -y \
	alsa-firmware \
	ffmpegthumbnailer \
	intel-vaapi-driver \
	libheif \
	libva-utils \
	pipewire-libs-extra

dnf5 config-manager setopt fedora-multimedia.enabled=0
