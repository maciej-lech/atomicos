#!/usr/bin/bash

set -euo pipefail

dnf_repo_install_isolated() {
	local repo_url="$1"
	shift

	if [[ -z "$repo_url" || $# -eq 0 ]]; then
		echo "ERROR: dnf_repo_install_isolated requires <repo_url> <dnf args...>"
		return 1
	fi

	local repo_file
	repo_file=$(basename "$repo_url")

	if [[ ! -f "/etc/yum.repos.d/$repo_file" ]]; then
		echo "Adding repo $repo_file (disabled by default)"
		dnf5 config-manager addrepo --from-repofile="$repo_url"
		sed -i 's/^enabled=.*$/enabled=0/' "/etc/yum.repos.d/$repo_file"
	fi

	echo "Installing from $repo_file (isolated): $*"
	dnf5 -y install "$@"
	echo "Installed from $repo_file"
}

copr_install_isolated() {
	local copr_name="$1"
	shift

	local dnf_opts=()
	local packages=()
	for arg in "$@"; do
		if [[ "$arg" == --* ]]; then
			dnf_opts+=("$arg")
		else
			packages+=("$arg")
		fi
	done

	if [[ ${#packages[@]} -eq 0 ]]; then
		echo "ERROR: No packages specified for copr_install_isolated"
		return 1
	fi

	repo_id="copr:copr.fedorainfracloud.org:${copr_name//\//:}"

	echo "Installing ${packages[*]} from COPR $copr_name (isolated)"

	dnf5 -y copr enable "$copr_name"
	dnf5 -y copr disable "$copr_name"
	dnf5 -y install --enablerepo="$repo_id" "${dnf_opts[@]}" "${packages[@]}"

	echo "Installed ${packages[*]} from $copr_name"
}

# RPM Fusion ships no plain repo file, only a release RPM that also carries the
# GPG keys its repo files point at.
rpmfusion_install_isolated() {
	local dnf_opts=()
	local packages=()
	for arg in "$@"; do
		if [[ "$arg" == --* ]]; then
			dnf_opts+=("$arg")
		else
			packages+=("$arg")
		fi
	done

	if [[ ${#packages[@]} -eq 0 ]]; then
		echo "ERROR: No packages specified for rpmfusion_install_isolated"
		return 1
	fi

	if [[ ! -f /etc/yum.repos.d/rpmfusion-free.repo ]]; then
		echo "Installing RPM Fusion free release (disabled by default)"
		dnf5 -y install \
			"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E '%{fedora}').noarch.rpm"
		sed -i 's/^enabled=1$/enabled=0/' /etc/yum.repos.d/rpmfusion-free*.repo
	fi

	local enable_repos=(--enablerepo=rpmfusion-free --enablerepo=rpmfusion-free-updates)
	if [[ -f /etc/yum.repos.d/rpmfusion-free-rawhide.repo ]]; then
		enable_repos=(--enablerepo=rpmfusion-free-rawhide)
	fi

	echo "Installing ${packages[*]} from RPM Fusion (isolated)"
	dnf5 -y install "${enable_repos[@]}" "${dnf_opts[@]}" "${packages[@]}"
	echo "Installed ${packages[*]} from RPM Fusion"
}

terra_install_isolated() {
	local dnf_opts=()
	local packages=()
	for arg in "$@"; do
		if [[ "$arg" == --* ]]; then
			dnf_opts+=("$arg")
		else
			packages+=("$arg")
		fi
	done

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
	dnf5 -y install --enablerepo=terra "${dnf_opts[@]}" "${packages[@]}"
	echo "Installed ${packages[*]} from Terra"
}
