#!/usr/bin/bash

set -euo pipefail

copr_install_isolated() {
	local copr_name="$1"
	shift
	local packages=("$@")

	if [[ ${#packages[@]} -eq 0 ]]; then
		echo "ERROR: No packages specified for copr_install_isolated"
		return 1
	fi

	repo_id="copr:copr.fedorainfracloud.org:${copr_name//\//:}"

	echo "Installing ${packages[*]} from COPR $copr_name (isolated)"

	dnf5 -y copr enable "$copr_name"
	dnf5 -y copr disable "$copr_name"
	dnf5 -y install --enablerepo="$repo_id" "${packages[@]}"

	echo "Installed ${packages[*]} from $copr_name"
}

terra_install_isolated() {
	local packages=("$@")

	if [[ ${#packages[@]} -eq 0 ]]; then
		echo "ERROR: No packages specified for terra_install_isolated"
		return 1
	fi

	if [[ ! -f /etc/yum.repos.d/terra.repo ]]; then
		echo "Installing Terra repo file (disabled by default)"
		curl -fsSLo /etc/yum.repos.d/terra.repo \
			https://raw.githubusercontent.com/terrapkg/subatomic-repos/main/terra.repo
		sed -i 's/^enabled=1$/enabled=0/' /etc/yum.repos.d/terra.repo
	fi

	echo "Installing ${packages[*]} from Terra (isolated)"
	dnf5 -y install --enablerepo=terra "${packages[@]}"
	echo "Installed ${packages[*]} from Terra"
}
