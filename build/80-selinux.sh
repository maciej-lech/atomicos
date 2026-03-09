#!/usr/bin/bash

set -eoux pipefail

# Libvirt SELinux workaround
cat > /usr/lib/systemd/system/libvirt-workaround.service <<'UNIT'
[Unit]
Description=Workaround to relabel libvirt files and directories
ConditionPathIsDirectory=/var/lib/libvirt/
After=local-fs.target

[Service]
Type=oneshot
ExecStart=-/usr/sbin/restorecon -R /var/log/libvirt/
ExecStart=-/usr/sbin/restorecon -R /var/lib/libvirt/
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT

# swtpm SELinux workaround
cat > /usr/lib/systemd/system/swtpm-workaround.service <<'UNIT'
[Unit]
Description=Workaround swtpm not having the correct label
ConditionFileIsExecutable=/usr/bin/swtpm
After=local-fs.target

[Service]
Type=oneshot
ExecStartPre=/usr/bin/bash -c "[ -x /usr/local/bin/overrides/swtpm ] || /usr/bin/cp /usr/bin/swtpm /usr/local/bin/overrides/swtpm"
ExecStartPre=/usr/bin/mount --bind /usr/local/bin/overrides/swtpm /usr/bin/swtpm
ExecStart=/usr/sbin/restorecon /usr/bin/swtpm
ExecStop=/usr/bin/umount /usr/bin/swtpm
ExecStop=/usr/bin/rm /usr/local/bin/overrides/swtpm
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT

systemctl enable swtpm-workaround.service
systemctl enable libvirt-workaround.service
