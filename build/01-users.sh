#!/usr/bin/bash

set -eoux pipefail

# Create the accounts the image adds with pinned IDs before any package install;
# packages then find them instead of allocating IDs that drift between builds
install -Dm0644 -t /usr/lib/sysusers.d /ctx/system/usr/lib/sysusers.d/00-atomicos-ids.conf
systemd-sysusers /usr/lib/sysusers.d/00-atomicos-ids.conf
