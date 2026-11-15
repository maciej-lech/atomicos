# COPR "make srpm" entry point: COPR runs this as root in a mock chroot, in the package
# subdirectory (packages/<name>), with outdir and spec set
copr_dir := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

.PHONY: srpm
srpm:
	dnf -y install curl rpm-build rpmdevtools
	"$(copr_dir)srpm.sh" "$(outdir)" "$(spec)"
