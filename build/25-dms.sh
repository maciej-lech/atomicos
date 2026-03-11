#!/usr/bin/bash

set -eoux pipefail

dnf5 -y copr enable avengemedia/dms
dnf5 -y copr disable avengemedia/dms
dnf5 -y install \
  --enablerepo="copr:copr.fedorainfracloud.org:avengemedia:dms" \
  --enablerepo="coprdep:copr.fedorainfracloud.org:avengemedia:danklinux" \
  cliphist dms dms-greeter niri waypipe

cat > /usr/lib/sysusers.d/dms-greeter.conf <<'SYSUSERS'
u greeter 962 "System Greeter" /var/lib/greeter /bin/bash
SYSUSERS

cat > /usr/lib/tmpfiles.d/dms-greeter.conf <<'TMPFILES'
d /var/lib/greetd/.config 0755 greetd greetd - -
d /var/lib/greetd/.config/systemd 0755 greetd greetd - -
d /var/lib/greetd/.config/systemd/user 0755 greetd greetd - -
L /var/lib/greetd/.config/systemd/user/xdg-desktop-portal.service - - - - /dev/null
TMPFILES
