#!/usr/bin/bash

set -euo pipefail

# dnf accepts enabled = 1/true/yes/on in any case, with optional whitespace
REPO_ENABLED_RE='^[[:space:]]*enabled[[:space:]]*=[[:space:]]*(1|true|yes|on)[[:space:]]*$'

repo_disable() {
	sed -i -E 's/^[[:space:]]*enabled[[:space:]]*=.*$/enabled=0/I' "$@"
}

is_repo_enabled() {
	grep -qiE "$REPO_ENABLED_RE" "$1"
}

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
		repo_disable "/etc/yum.repos.d/$repo_file"
	fi

	echo "Installing from $repo_file (isolated): $*"
	dnf5 -y install "$@"
	echo "Installed from $repo_file"
}

copr_install_isolated() {
	local copr_name="$1"
	shift

	local chroot=()
	local dnf_opts=()
	local packages=()
	for arg in "$@"; do
		case "$arg" in
		--chroot=*) chroot=("${arg#--chroot=}") ;;
		--*) dnf_opts+=("$arg") ;;
		*) packages+=("$arg") ;;
		esac
	done

	if [[ ${#packages[@]} -eq 0 ]]; then
		echo "ERROR: No packages specified for copr_install_isolated"
		return 1
	fi

	repo_id="copr:copr.fedorainfracloud.org:${copr_name//\//:}"

	echo "Installing ${packages[*]} from COPR $copr_name (isolated)"

	dnf5 -y copr enable "$copr_name" "${chroot[@]}"
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

	if ! rpm -q --quiet rpmfusion-free-release; then
		echo "Installing RPM Fusion free release (disabled by default)"
		local release_path
		release_path="free/fedora/rpmfusion-free-release-$(rpm -E '%{fedora}').noarch.rpm"
		# mirrors.rpmfusion.org redirects by client location and can land on a dead mirror
		dnf5 -y install "https://mirrors.rpmfusion.org/$release_path" || {
			echo "Mirror redirect failed, falling back to download1.rpmfusion.org"
			dnf5 -y install "https://download1.rpmfusion.org/$release_path"
		}
		# rpmfusion-free-release 45-2 moved its repo files to /usr/share/dnf5/repos.d,
		# stale mirrors still serve builds that use /etc/yum.repos.d
		local repo
		for repo in /etc/yum.repos.d/rpmfusion-free*.repo /usr/share/dnf5/repos.d/rpmfusion-free*.repo; do
			if [[ -f "$repo" ]]; then
				repo_disable "$repo"
			fi
		done
	fi

	local enable_repos=(--enablerepo=rpmfusion-free --enablerepo=rpmfusion-free-updates)
	if [[ -f /etc/yum.repos.d/rpmfusion-free-rawhide.repo || -f /usr/share/dnf5/repos.d/rpmfusion-free-rawhide.repo ]]; then
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
		echo "Installing vendored Terra repo file and keys (disabled by default)"
		install -m0644 /ctx/system/etc/yum.repos.d/terra.repo /etc/yum.repos.d/terra.repo
		install -m0644 -D -t /etc/pki/rpm-gpg /ctx/system/etc/pki/rpm-gpg/RPM-GPG-KEY-terra*
		repo_disable /etc/yum.repos.d/terra.repo
	fi

	echo "Installing ${packages[*]} from Terra (isolated)"
	dnf5 -y install --enablerepo=terra "${dnf_opts[@]}" "${packages[@]}"
	echo "Installed ${packages[*]} from Terra"
}
