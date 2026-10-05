#!/usr/bin/env bash
# Append brew after system binaries so its dependencies (dbus, curl, mount...) don't shadow them.
# HOMEBREW_PREFIX check skips nested shells that inherited the setup.
if [[ $- == *i* && -z "${HOMEBREW_PREFIX:-}" && -d /home/linuxbrew/.linuxbrew ]]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash | grep -Ev '\bPATH=')"
	export PATH="${PATH}:${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin"
fi
