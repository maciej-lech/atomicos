export image_name := env("IMAGE_NAME", "atomicos")
export default_tag := env("DEFAULT_TAG", "stable")
export image_registry := env("IMAGE_REGISTRY", "ghcr.io/maciej-lech")
export bib_image := env("BIB_IMAGE", "ghcr.io/osbuild/bootc-image-builder:latest@sha256:2d29e039bbc0a87506055368fa1ac1c1a511cefe762a95dd099e89e517701080")
export qemu_image := env("QEMU_IMAGE", "ghcr.io/qemus/qemu:7.50@sha256:e7f6fda52503a546fd649670ba46e4bc23dc6dcef275bc3fac48877fbbc430df")
brewfile := "system/usr/share/atomicos/Brewfile"
brew_dump_flags := "--no-describe --no-vscode --no-go --no-cargo --no-uv --no-npm --no-krew"

alias build-vm := build-qcow2
alias rebuild-vm := rebuild-qcow2
alias run-vm := run-vm-qcow2

[private]
default:
    @just --list

# Clean Repo
clean:
    #!/usr/bin/bash
    set -eoux pipefail
    touch _build
    find *_build* -exec rm -rf {} \;
    rm -f previous.manifest.json
    rm -f changelog.md
    rm -f output.env
    rm -rf output/

# This Justfile recipe builds a container image using Podman.
#
# Arguments:
#   $target_image - The tag you want to apply to the image (default: $image_name).
#   $tag - The tag for the image (default: $default_tag).
#
# The script constructs the version string using the tag and the current date.
# If the git working directory is clean, it also includes the short SHA of the current HEAD.
#
# just build $target_image $tag
#
# Example usage:
#   just build aurora lts
#
# This will build an image 'aurora:lts' with DX and GDX enabled.
#

# Build the image using the specified parameters
build $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash

    BUILD_ARGS=()
    if [[ -z "$(git status -s)" ]]; then
        BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    fi

    podman build \
        "${BUILD_ARGS[@]}" \
        --pull=newer \
        --tag "${target_image}:${tag}" \
        .

# Split the image into package-based layers for smaller delta updates
rechunk $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -xeuo pipefail

    # The image itself ships rpm-ostree, so it doubles as the chunker
    GRAPHROOT="$(podman info --format '{{ '{{.Store.GraphRoot}}' }}')"

    # 90-cleanup.sh empties /var, but rpm-ostree needs a disk-backed /var/tmp
    VARTMP="$(mktemp -p "${PWD}" -d -t _build-rechunk.XXXXXXXXXX)"
    trap 'podman unshare rm -rf "${VARTMP}"' EXIT

    # build-chunked-oci drops the source labels; carry them over except the
    # content hashes it regenerates
    mapfile -t LABELS < <(podman image inspect "${target_image}:${tag}" | jq -r '
      .[0].Labels | to_entries[]
      | select(.key | IN("ostree.commit", "ostree.final-diffid", "rpmostree.inputhash") | not)
      | "--label=\(.key)=\(.value)"')

    podman run --rm --pull=never --privileged \
      --mount=type=image,src="${target_image}:${tag}",target=/rpm-ostree \
      --mount=type=bind,src="${VARTMP}",target=/var/tmp,rw \
      --mount=type=bind,src="${GRAPHROOT}",target=/run/host-container-storage,rw \
      --mount=type=tmpfs,target=/run/rpm-ostree-storage \
      --entrypoint /usr/bin/rpm-ostree \
      "localhost/${target_image}:${tag}" \
      compose build-chunked-oci \
      --max-layers 127 \
      --format-version=2 \
      --bootc \
      --rootfs /rpm-ostree \
      "${LABELS[@]}" \
      --output "containers-storage:[overlay@/run/host-container-storage+/run/rpm-ostree-storage]localhost/${target_image}:${tag}"

# Command: _rootful_load_image
# Description: This script checks if the current user is root or running under sudo. If not, it attempts to resolve the image tag using podman inspect.
#              If the image is found, it loads it into rootful podman. If the image is not found, it pulls it from the repository.
#
# Parameters:
#   $target_image - The name of the target image to be loaded or pulled.
#   $tag - The tag of the target image to be loaded or pulled. Default is 'default_tag'.
#
# Example usage:
#   _rootful_load_image my_image latest
#
# Steps:
# 1. Check if the script is already running as root or under sudo.
# 2. Check if target image is in the non-root podman container storage)
# 3. If the image is found, load it into rootful podman using podman scp.
# 4. If the image is not found, pull it from the remote repository into reootful podman.

_rootful_load_image $target_image=image_name $tag=default_tag:
    #!/usr/bin/bash
    set -eoux pipefail

    # Cache sudo credentials for subsequent commands
    sudo -v

    # Check if already running as root or under sudo
    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
        echo "Already root or running under sudo, no need to load image from user podman."
        exit 0
    fi

    if podman image exists "${target_image}:${tag}"; then
        # If the image is found, load it into rootful podman
        USER_IMG_ID=$(podman images -q "${target_image}:${tag}")
        ID=$(sudo podman images -q "${target_image}:${tag}")
        if [[ "$ID" != "$USER_IMG_ID" ]]; then
            # If the image ID is not found or different from user, copy the image from user podman to root podman
            COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
            sudo TMPDIR=${COPYTMP} podman image scp ${UID}@localhost::"${target_image}:${tag}" root@localhost::"${target_image}:${tag}"
            rm -rf "${COPYTMP}"
        fi
    else
        # If the image is not found, pull it from the repository
        sudo podman pull "${target_image}:${tag}"
    fi

# Build a bootc bootable image using Bootc Image Builder (BIB)
# Converts a container image to a bootable image
# Parameters:
#   target_image: The name of the image to build (ex. localhost/fedora)
#   tag: The tag of the image to build (ex. latest)
#   type: The type of image to build (ex. qcow2, raw, iso)
#   config: The configuration file to use for the build (default: iso/disk.toml)

# Example: just _rebuild-bib localhost/fedora latest qcow2 iso/disk.toml
_build-bib $target_image $tag $type $config: (_rootful_load_image target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail

    # Cache sudo credentials for subsequent commands
    sudo -v

    args="--type ${type} "
    args+="--use-librepo=True "
    args+="--rootfs=btrfs"

    BUILDTMP=$(mktemp -p "${PWD}" -d -t _build-bib.XXXXXXXXXX)
    trap 'sudo rm -rf "${BUILDTMP}"' EXIT
    mkdir "${BUILDTMP}/output"

    # BIB records the bootc origin from the image reference it is given, so an
    # ISO built from the local tag would install a system tracking localhost/.
    # The ISO kickstart switches that same reference to a signature-enforced one.
    build_image="${target_image}:${tag}"
    config_file="${PWD}/${config}"
    if [[ "${type}" == "iso" ]]; then
        build_image="${image_registry}/${image_name}:${tag}"
        sudo podman tag "${target_image}:${tag}" "${build_image}"
        if ! grep -q '@IMAGE_REF@' "${config}"; then
            echo "ERROR: ${config} lacks the @IMAGE_REF@ sigpolicy switch; installs would skip signature checks" >&2
            exit 1
        fi
        config_file="${BUILDTMP}/config.toml"
        sed "s|@IMAGE_REF@|${build_image}|g" "${config}" > "${config_file}"
    fi

    sudo podman run \
      --rm \
      --privileged \
      --net=host \
      --security-opt label=type:unconfined_t \
      -v "${config_file}:/config.toml:ro" \
      -v "${BUILDTMP}/output:/output" \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" \
      ${args} \
      "${build_image}"

    mkdir -p output
    sudo cp -af "${BUILDTMP}"/output/* output/
    sudo chown -R "$(id -u):$(id -g)" output/

# Podman builds the image from the Containerfile and creates a bootable image
# Parameters:
#   target_image: The name of the image to build (ex. localhost/fedora)
#   tag: The tag of the image to build (ex. latest)
#   type: The type of image to build (ex. qcow2, raw, iso)
#   config: The configuration file to use for the build (deafult: iso/disk.toml)

# Example: just _rebuild-bib localhost/fedora latest qcow2 iso/disk.toml
_rebuild-bib $target_image $tag $type $config: (build target_image tag) && (_build-bib target_image tag type config)

# Build a QCOW2 virtual machine image
[group('Build Virtal Machine Image')]
build-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "qcow2" "iso/disk.toml")

# Build a RAW virtual machine image
[group('Build Virtal Machine Image')]
build-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "raw" "iso/disk.toml")

# Build an ISO virtual machine image
[group('Build Virtal Machine Image')]
build-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "iso" "iso/iso.toml")

# Rebuild a QCOW2 virtual machine image
[group('Build Virtal Machine Image')]
rebuild-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "qcow2" "iso/disk.toml")

# Rebuild a RAW virtual machine image
[group('Build Virtal Machine Image')]
rebuild-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "raw" "iso/disk.toml")

# Rebuild an ISO virtual machine image
[group('Build Virtal Machine Image')]
rebuild-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "iso" "iso/iso.toml")

# Run a virtual machine with the specified image type and configuration
_run-vm $target_image $tag $type $config:
    #!/usr/bin/bash
    set -eoux pipefail

    # BIB output directories follow osbuild export names, not the type.
    # Disk images boot with -snapshot so the guest never writes to the build
    # artifact; the ISO installs onto the container's throwaway disk.
    case "${type}" in
        qcow2) image_file="output/qcow2/disk.qcow2"; boot_mount="/boot.qcow2"; qemu_args="-snapshot" ;;
        raw) image_file="output/image/disk.raw"; boot_mount="/boot.img"; qemu_args="-snapshot" ;;
        iso) image_file="output/bootiso/install.iso"; boot_mount="/boot.iso"; qemu_args="" ;;
        *) echo "ERROR: unknown image type '${type}' (expected qcow2, raw or iso)" >&2; exit 1 ;;
    esac

    if ! command -v podman >/dev/null; then
        echo "ERROR: podman not found" >&2
        exit 1
    fi
    if [[ ! -w /dev/kvm ]]; then
        echo "ERROR: /dev/kvm is missing or not writable (add your user to the kvm group)" >&2
        exit 1
    fi

    # Build the image if it does not exist
    if [[ ! -f "${image_file}" ]]; then
        just "build-${type}" "$target_image" "$tag"
    fi

    # Determine an available port to use
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Set up the arguments for running the VM
    run_args=()
    run_args+=(--rm --privileged)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=8G")
    run_args+=(--env "DISK_SIZE=64G")
    run_args+=(--env "BOOT_MODE=uefi")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    [[ -n "${qemu_args}" ]] && run_args+=(--env "ARGUMENTS=${qemu_args}")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "${PWD}/${image_file}:${boot_mount}")
    run_args+=("${qemu_image}")

    # Run the VM and open the browser to connect
    (sleep 30 && xdg-open http://localhost:"$port") &
    podman run "${run_args[@]}"

# Run a virtual machine from a QCOW2 image
[group('Run Virtal Machine')]
run-vm-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "qcow2" "iso/disk.toml")

# Run a virtual machine from a RAW image
[group('Run Virtal Machine')]
run-vm-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "raw" "iso/disk.toml")

# Run a virtual machine from an ISO
[group('Run Virtal Machine')]
run-vm-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "iso" "iso/iso.toml")

# Run a virtual machine from a QCOW2 or RAW image using systemd-vmspawn
[group('Run Virtal Machine')]
spawn-vm rebuild="0" type="qcow2" ram="6G":
    #!/usr/bin/env bash

    set -euo pipefail

    case "{{ type }}" in
        qcow2) image_file="output/qcow2/disk.qcow2" ;;
        raw) image_file="output/image/disk.raw" ;;
        *) echo "ERROR: spawn-vm boots qcow2 or raw disk images; use 'just run-vm-iso' for an ISO" >&2; exit 1 ;;
    esac

    for dep in systemd-vmspawn qemu-img; do
        if ! command -v "${dep}" >/dev/null; then
            echo "ERROR: ${dep} not found; use 'just run-vm-{{ type }}' instead" >&2
            exit 1
        fi
    done
    if ! command -v qemu-kvm >/dev/null && ! command -v qemu-system-x86_64 >/dev/null; then
        echo "ERROR: qemu-kvm or qemu-system-x86_64 not found; use 'just run-vm-{{ type }}' instead" >&2
        exit 1
    fi
    if [[ ! -w /dev/kvm ]]; then
        echo "ERROR: /dev/kvm is missing or not writable (add your user to the kvm group)" >&2
        exit 1
    fi

    if [[ "{{ rebuild }}" == 1 ]]; then
        echo "Rebuilding the {{ type }} image"
        just "rebuild-{{ type }}"
    elif [[ ! -f "${image_file}" ]]; then
        just "build-{{ type }}"
    fi

    # vmspawn only accepts raw images and writes to them, so boot a scratch copy
    SCRATCH="$(mktemp -p "${PWD}" -d -t _build-vmspawn.XXXXXXXXXX)"
    trap 'rm -rf "${SCRATCH}"' EXIT
    qemu-img convert -p -f "{{ type }}" -O raw "${image_file}" "${SCRATCH}/disk.raw"

    systemd-vmspawn \
      -M "bootc-image" \
      --console=gui \
      --cpus=2 \
      --ram=$(echo {{ ram }}| /usr/bin/numfmt --from=iec) \
      --network-user-mode \
      --vsock=false --pass-ssh-key=false \
      -i "${SCRATCH}/disk.raw"

# Compare Brewfile with installed packages: missing (listed, not installed) and extra (installed, not listed)
[group('Apps')]
apps-diff:
    #!/usr/bin/env bash
    set -euo pipefail
    export LC_ALL=C
    section() {
        echo "# $1"
        echo "${2:-# none}"
    }
    err=$(mktemp)
    trap 'rm -f "$err"' EXIT
    if ! installed=$(brew bundle dump {{ brew_dump_flags }} --file=- 2>"$err" | sort); then
        cat "$err" >&2
        exit 1
    fi
    listed=$(sort {{ brewfile }})
    section "Missing (listed, not installed)" "$(comm -23 <(echo "$listed") <(echo "$installed"))"
    echo
    section "Extra (installed, not listed)" "$(comm -13 <(echo "$listed") <(echo "$installed"))"

# Print installed packages in Brewfile format
[group('Apps')]
apps-dump:
    @brew bundle dump {{ brew_dump_flags }} --file=-

# Refresh vendored Flathub descriptor, Terra repo, Terra keys and source image cosign keys from upstream; review the git diff, these are trust roots
update-vendored:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    keydir=system/etc/pki/rpm-gpg

    curl -fsSL -o "$tmp/flathub.flatpakrepo" https://dl.flathub.org/repo/flathub.flatpakrepo

    # Ship disabled and point gpgkey at the vendored key instead of fetching it at install time
    curl -fsSL https://raw.githubusercontent.com/terrapkg/subatomic-repos/main/terra.repo \
        | sed -E -e 's/^enabled=.*/enabled=0/' \
            -e 's|^gpgkey=https://repos\.fyralabs\.com/terra\$releasever/key\.asc$|gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-terra$releasever|' \
        > "$tmp/terra.repo"
    if grep -qE '^gpgkey=.*https?://' "$tmp/terra.repo"; then
        echo "terra.repo: upstream gpgkey format changed, remote key left after rewrite" >&2
        exit 1
    fi

    # Terra signs each Fedora release with its own key; vendor current and next so a rebase works
    fedora=$(sed -nE 's/^FROM .*base-atomic:([0-9]+)@.*/\1/p' Containerfile)
    mkdir "$tmp/keys"
    for release in "$fedora" "$((fedora + 1))"; do
        key="RPM-GPG-KEY-terra$release"
        if curl -fsSL -o "$tmp/keys/$key" "https://repos.fyralabs.com/terra$release/key.asc"; then
            gpg --show-keys "$tmp/keys/$key" >/dev/null
        elif [[ "$release" != "$fedora" && -f "$keydir/$key" ]]; then
            cp "$keydir/$key" "$tmp/keys/"
        elif [[ "$release" == "$fedora" ]]; then
            echo "Missing Terra key for Fedora $release" >&2
            exit 1
        fi
    done

    # Keys CI verifies Containerfile source images against
    mkdir "$tmp/cosign"
    curl -fsSL -o "$tmp/cosign/quay.io-fedora-ostree-desktops.pub" https://gitlab.com/fedora/ostree/ci-test/-/raw/main/quay.io-fedora-ostree-desktops.pub
    curl -fsSL -o "$tmp/cosign/ghcr.io-ublue-os.pub" https://raw.githubusercontent.com/ublue-os/main/main/cosign.pub
    for key in "$tmp/cosign"/*.pub; do
        openssl pkey -pubin -in "$key" -noout
    done

    # Handy signs its release assets with the Tauri updater key; take it from the pinned tag
    handy_version=$(sed -nE 's/^HANDY_VERSION="([^"]+)"$/\1/p' build/16-graphical.sh)
    curl -fsSL "https://raw.githubusercontent.com/cjpais/Handy/v$handy_version/src-tauri/tauri.conf.json" \
        | jq -er .plugins.updater.pubkey | base64 -d > "$tmp/handy-minisign.pub"
    if ! head -n1 "$tmp/handy-minisign.pub" | grep -q '^untrusted comment: minisign public key' \
        || [[ "$(sed -n 2p "$tmp/handy-minisign.pub" | base64 -d | head -c2)" != Ed ]]; then
        echo "Handy updater pubkey is not a minisign Ed25519 public key" >&2
        exit 1
    fi

    install -m0644 "$tmp/flathub.flatpakrepo" system/etc/flatpak/remotes.d/flathub.flatpakrepo
    install -m0644 "$tmp/terra.repo" system/etc/yum.repos.d/terra.repo
    rm -f "$keydir"/RPM-GPG-KEY-terra*
    install -m0644 -D -t "$keydir" "$tmp/keys"/*
    install -m0644 -D -t .github/cosign "$tmp/cosign"/*.pub
    install -m0644 -D -t build/keys "$tmp/handy-minisign.pub"
    git status --short system/etc .github/cosign build/keys

# List shell scripts git tracks: *.sh plus sh/bash shebang scripts under build/ and system/
shell-sources:
    #!/usr/bin/env bash
    set -euo pipefail
    {
        git ls-files '*.sh'
        git ls-files build system | while IFS= read -r f; do
            if [[ -f "$f" && ! -L "$f" ]] && head -n1 "$f" | grep -Eq '^#!\s*(/usr)?/bin/(env\s+)?(ba)?sh(\s|$)'; then
                echo "$f"
            fi
        done
    } | sort -u

# Lint all Bash scripts, Justfiles and Containerfile
lint:
    #!/usr/bin/env bash
    set -eoux pipefail
    if ! command -v shellcheck &> /dev/null; then
        echo "shellcheck could not be found. Please install it."
        exit 1
    fi
    just --unstable --fmt --check -f Justfile
    git ls-files '*.just' | xargs -I{} just --unstable --fmt --check -f {}
    mapfile -t sources < <(just shell-sources)
    shellcheck -x "${sources[@]}"
    if command -v hadolint &> /dev/null; then
        hadolint --config .github/hadolint.yaml Containerfile
    else
        echo "hadolint not found, skipping Containerfile lint"
    fi

# Format all Bash scripts and Justfiles
format:
    #!/usr/bin/env bash
    set -eoux pipefail
    if ! command -v shfmt &> /dev/null; then
        echo "shfmt could not be found. Please install it."
        exit 1
    fi
    just --unstable --fmt -f Justfile
    git ls-files '*.just' | xargs -I{} just --unstable --fmt -f {}
    git ls-files '*.sh' | xargs shfmt --write
