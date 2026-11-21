#!/usr/bin/fish
#shellcheck disable=all
# Runs in non-interactive shells too (ssh host cmd, fish -c, agent tools).
# HOMEBREW_PREFIX check skips nested shells that inherited the setup.
if not set -q HOMEBREW_PREFIX; and test -d /home/linuxbrew/.linuxbrew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source
    # Append brew after system binaries so its dependencies (dbus, curl, mount...) don't shadow them
    fish_add_path --global --move --append --path $HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin
    set -gx HOMEBREW_BUNDLE_FILE_GLOBAL /usr/share/atomicos/Brewfile
end

if status --is-interactive; and set -q HOMEBREW_PREFIX
    for dir in $HOMEBREW_PREFIX/share/fish/completions $HOMEBREW_PREFIX/share/fish/vendor_completions.d
        if test -d $dir; and not contains -- $dir $fish_complete_path
            set -ga fish_complete_path $dir
        end
    end
end
