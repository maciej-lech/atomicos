export image_name := env("IMAGE_NAME", "atomicos")
export default_tag := env("DEFAULT_TAG", "stable")
export image_registry := env("IMAGE_REGISTRY", "ghcr.io/maciej-lech")
export bib_image := env("BIB_IMAGE", "ghcr.io/osbuild/bootc-image-builder:latest@sha256:af9c0ee0b206a80f2905137b14737deb42ed4889df69e66b57c4496a12ec30ae")
export qemu_image := env("QEMU_IMAGE", "ghcr.io/qemus/qemu:7.50@sha256:e7f6fda52503a546fd649670ba46e4bc23dc6dcef275bc3fac48877fbbc430df")

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

    # BIB records the bootc origin from the image reference it is given, so an
    # ISO built from the local tag would install a system tracking localhost/.
    build_image="${target_image}:${tag}"
    if [[ "${type}" == "iso" ]]; then
        build_image="${image_registry}/${image_name}:${tag}"
        sudo podman tag "${target_image}:${tag}" "${build_image}"
    fi

    BUILDTMP=$(mktemp -p "${PWD}" -d -t _build-bib.XXXXXXXXXX)
    trap 'sudo rm -rf "${BUILDTMP}"' EXIT

    sudo podman run \
      --rm \
      --privileged \
      --net=host \
      --security-opt label=type:unconfined_t \
      -v "${PWD}/${config}:/config.toml:ro" \
      -v "${BUILDTMP}:/output" \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" \
      ${args} \
      "${build_image}"

    mkdir -p output
    sudo cp -af "${BUILDTMP}"/* output/
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

    # BIB output directories follow osbuild export names, not the type
    case "${type}" in
        qcow2) image_file="output/qcow2/disk.qcow2"; boot_mount="/boot.qcow2" ;;
        raw) image_file="output/image/disk.raw"; boot_mount="/boot.img" ;;
        iso) image_file="output/bootiso/install.iso"; boot_mount="/boot.iso" ;;
    esac

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
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
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

# Run a virtual machine using systemd-vmspawn
[group('Run Virtal Machine')]
spawn-vm rebuild="0" type="qcow2" ram="6G":
    #!/usr/bin/env bash

    set -euo pipefail

    [ "{{ rebuild }}" -eq 1 ] && echo "Rebuilding the ISO" && just build-vm {{ rebuild }} {{ type }}

    systemd-vmspawn \
      -M "bootc-image" \
      --console=gui \
      --cpus=2 \
      --ram=$(echo {{ ram }}| /usr/bin/numfmt --from=iec) \
      --network-user-mode \
      --vsock=false --pass-ssh-key=false \
      -i ./output/**/*.{{ type }}

# Lint all Bash scripts and Justfiles
lint:
    #!/usr/bin/env bash
    set -eoux pipefail
    if ! command -v shellcheck &> /dev/null; then
        echo "shellcheck could not be found. Please install it."
        exit 1
    fi
    just --unstable --fmt --check -f Justfile
    git ls-files '*.just' | xargs -I{} just --unstable --fmt --check -f {}
    git ls-files '*.sh' | xargs shellcheck

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
