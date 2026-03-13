#!/usr/bin/bash

set -eoux pipefail

dnf5 remove -y \
	default-fonts-cjk-sans \
	fedora-third-party \
	fedora-workstation-repositories \
	google-noto-sans-cjk-vf-fonts

rm -f /etc/yum.repos.d/google-chrome.repo
rm -f /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo
rm -f /etc/yum.repos.d/rpmfusion-nonfree-steam.repo
rm -f "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo"
