#!/usr/bin/bash

set -euo pipefail

dnf_var() {
	dnf5 --dump-variables | awk -v key="$1" '$1 == key { print $3; exit }'
}

repo_baseurl_available() {
	local repo_file="$1"
	local url

	url=$(sed -n 's/^baseurl=//p' "$repo_file" | head -1)
	[[ -n "$url" ]] || return 0

	url="${url//\$releasever/$(dnf_var releasever)}"
	url="${url//\$basearch/$(dnf_var basearch)}"

	curl -fsL --retry 2 -o /dev/null "${url%/}/repodata/repomd.xml"
}

# --fallback-repo-releasever=N rewrites $releasever in the repo file when the
# vendor publishes nothing for the release being built.
dnf_repo_install_isolated() {
	local repo_url="$1"
	shift

	local fallback_releasever=""
	local dnf_args=()
	for arg in "$@"; do
		case "$arg" in
		--fallback-repo-releasever=*) fallback_releasever="${arg#--fallback-repo-releasever=}" ;;
		*) dnf_args+=("$arg") ;;
		esac
	done

	if [[ -z "$repo_url" || ${#dnf_args[@]} -eq 0 ]]; then
		echo "ERROR: dnf_repo_install_isolated requires <repo_url> <dnf args...>"
		return 1
	fi

	local repo_file
	repo_file=$(basename "$repo_url")

	if [[ ! -f "/etc/yum.repos.d/$repo_file" ]]; then
		echo "Adding repo $repo_file (disabled by default)"
		dnf5 config-manager addrepo --from-repofile="$repo_url"
		if [[ -n "$fallback_releasever" ]] && ! repo_baseurl_available "/etc/yum.repos.d/$repo_file"; then
			echo "$repo_file has nothing for $(dnf_var releasever), falling back to Fedora $fallback_releasever"
			sed -i "s/[$]releasever/$fallback_releasever/g" "/etc/yum.repos.d/$repo_file"
		fi
		sed -i 's/^enabled=.*$/enabled=0/' "/etc/yum.repos.d/$repo_file"
	fi

	echo "Installing from $repo_file (isolated): ${dnf_args[*]}"
	dnf5 -y install "${dnf_args[@]}"
	echo "Installed from $repo_file"
}

# --fallback-copr-releasever=N enables the fedora-N chroot when the project has no
# chroot for the release being built.
copr_install_isolated() {
	local copr_name="$1"
	shift

	local fallback_releasever=""
	local dnf_opts=()
	local packages=()
	for arg in "$@"; do
		case "$arg" in
		--fallback-copr-releasever=*) fallback_releasever="${arg#--fallback-copr-releasever=}" ;;
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

	if ! dnf5 -y copr enable "$copr_name"; then
		if [[ -z "$fallback_releasever" ]]; then
			return 1
		fi
		local chroot
		chroot="fedora-$fallback_releasever-$(dnf_var basearch)"
		echo "COPR $copr_name has no chroot for this release, falling back to $chroot"
		dnf5 -y copr enable "$copr_name" "$chroot"
	fi
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
