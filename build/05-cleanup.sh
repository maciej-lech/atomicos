#!/usr/bin/bash

set -eoux pipefail

# Keep downloaded packages in the /var/cache build cache mount; 90-cleanup.sh unsets it
dnf5 config-manager setopt keepcache=1

dnf5 remove -y \
	default-fonts-cjk-sans \
	fedora-third-party \
	fedora-workstation-repositories \
	google-noto-sans-cjk-vf-fonts

rm -f /etc/yum.repos.d/google-chrome.repo
rm -f /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo
rm -f /etc/yum.repos.d/rpmfusion-nonfree-steam.repo
rm -f "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo"
