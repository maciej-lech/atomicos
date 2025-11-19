#!/bin/bash

set -ouex pipefail

# Remove VS Code
sudo dnf5 remove -y code
sudo rm -f /etc/yum.repos.d/vscode.repo

# Clean up
dnf5 clean all
