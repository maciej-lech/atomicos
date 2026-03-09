#!/usr/bin/bash

set -eoux pipefail

dnf5 clean all

rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
