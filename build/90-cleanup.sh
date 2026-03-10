#!/usr/bin/bash

set -eoux pipefail

systemctl mask flatpak-add-fedora-repos.service
systemctl mask flatpak-preinstall.service

dnf5 clean all

rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
