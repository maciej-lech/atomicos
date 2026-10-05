#!/usr/bin/fish
#shellcheck disable=all
if status --is-interactive
    if test -d /home/linuxbrew/.linuxbrew
        /home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source
        # Append brew after system binaries so its dependencies (dbus, curl, mount...) don't shadow them
        fish_add_path --global --move --append --path $HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin
        if test -d $HOMEBREW_PREFIX/share/fish/completions
            set -ga fish_complete_path $HOMEBREW_PREFIX/share/fish/completions
        end
        if test -d $HOMEBREW_PREFIX/share/fish/vendor_completions.d
            set -ga fish_complete_path $HOMEBREW_PREFIX/share/fish/vendor_completions.d
        end
    end
end
