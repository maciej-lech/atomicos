# Packages

RPMs the image needs patched or rebuilt, built in COPR [`maciej-lech/atomicos`](https://copr.fedorainfracloud.org/coprs/maciej-lech/atomicos/)
for every chroot of the project (Fedora releases and rawhide).

## Layout

One directory per package, named after the package:

```
packages/<name>/
  <name>.spec    # usually Fedora's dist-git spec with a local change
  sources        # optional: Fedora lookaside entries ("SHA512 (file) = hash")
  lookaside      # optional: lookaside package name, if it differs from <name>
  *.patch, ...   # any other file is copied next to the spec as a source
```

`.copr/srpm.sh` builds the SRPM (COPR "make srpm" method through `.copr/Makefile`): local files, then `sources`
from `https://src.fedoraproject.org/repo/pkgs/rpms/<name>/...` checked against the SHA512, then any other URL source
from the spec. Test it locally with `rpm-build` and `rpmdevtools` installed:

```sh
cd packages/<name> && ../../.copr/srpm.sh /tmp/srpm <name>.spec
rpmbuild --rebuild /tmp/srpm/<name>-*.src.rpm
```

## Builds

`.github/workflows/copr.yml` runs on pushes to `master` that touch `packages/` or `.copr/` and builds only the changed
packages from the pushed commit; changes to the workflow alone (e.g. Renovate digest bumps) build nothing. Run it by
hand (Actions > COPR packages) to rebuild some or all packages. It needs the `COPR_CONFIG` secret: the content of
`~/.config/copr` from <https://copr.fedorainfracloud.org/api/>. The token expires after about 180 days; an auth error
means it needs renewing.

Failures in rawhide are only warnings.

The image build ignores pushes that only touch `packages/` or `.copr/`, since it would install the previous COPR build.
After the COPR build succeeds, start the image build by hand (Actions > Build container image, or
`gh workflow run build.yml -R maciej-lech/atomicos`). Keep package changes and image changes in separate pushes; a push
with both starts the image build right away, before COPR has the new package.

## Rules for patched Fedora packages

- `Release:` is Fedora's release plus `.N.atomicos` (e.g. `2.1.atomicos%{?dist}`), so it sorts above Fedora's build of
  the same version and below Fedora's next release
- Install it in the image with `copr_install_isolated "maciej-lech/atomicos" <name>` followed by
  `assert_from_repo "copr:copr.fedorainfracloud.org:maciej-lech:atomicos" <name>`. When Fedora ships a newer version,
  the image build fails instead of silently dropping the patch; rebase by copying Fedora's new spec and re-adding the
  local changes
- Merge the package change first and wait for the COPR build before switching the image to it

## niri

Fedora dist-git `rpms/niri` f45 (`e475123`) plus one patch from the `proto/pause-drm-on-exit-v26.04` branch: pause
the DRM devices before exit, so outputs stay lit for the next compositor at the greeter to session handoff (niri
discussion [#4763](https://github.com/niri-wm/niri/discussions/4763)). Regenerate the patch with
`git format-patch --no-signature v26.04..<branch>` and drop the email from the `From:` line.
