#!/usr/bin/bash
# Build an SRPM from the current package directory (packages/<name>)
# Usage: srpm.sh OUTDIR [SPEC]
#
# Sources come from, in order:
#   1. files next to the spec (patches, configs)
#   2. the "sources" file, fetched from Fedora's lookaside cache and checked against its SHA512
#      (the lookaside package name is the spec Name, or the content of a "lookaside" file)
#   3. remaining URL sources from the spec, fetched with curl
set -euo pipefail

outdir=$(realpath -m "${1:?usage: srpm.sh OUTDIR [SPEC]}")
spec=${2:-}
[[ -n $spec ]] || spec=$(ls ./*.spec)
spec=$(realpath "$spec")
pkgdir=$(dirname "$spec")
cd "$pkgdir"

name=$(rpmspec -q --srpm --qf '%{name}' "$spec")
lookaside_name=$(cat lookaside 2>/dev/null || echo "$name")

sourcedir=$(mktemp -d)
trap 'rm -rf "$sourcedir"' EXIT
find . -maxdepth 1 -type f ! -name '*.spec' ! -name sources ! -name lookaside -exec cp -t "$sourcedir" {} +

if [[ -f sources ]]; then
	while read -r line; do
		[[ $line =~ ^SHA512\ \((.+)\)\ =\ ([0-9a-f]{128})$ ]] || { echo "unsupported sources line: $line" >&2; exit 1; }
		file=${BASH_REMATCH[1]} hash=${BASH_REMATCH[2]}
		curl -fsSL --retry 3 -o "$sourcedir/$file" \
			"https://src.fedoraproject.org/repo/pkgs/rpms/$lookaside_name/$file/sha512/$hash/$file"
		echo "$hash  $sourcedir/$file" | sha512sum -c --quiet
	done < <(grep -v '^\s*$' sources)
fi

# Sources not provided above, fetched from their URL
while read -r _ url; do
	file=${url##*/}
	[[ -e $sourcedir/$file ]] && continue
	[[ $url == *://* ]] || { echo "missing local source: $url" >&2; exit 1; }
	curl -fsSL --retry 3 -o "$sourcedir/$file" "$url"
done < <(spectool -l -a "$spec")

mkdir -p "$outdir"
rpmbuild -bs --define "_sourcedir $sourcedir" --define "_srcrpmdir $outdir" "$spec"
