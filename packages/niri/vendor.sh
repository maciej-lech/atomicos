#!/usr/bin/bash

set -e

NAME=niri
SPEC="${NAME}.spec"
VERSION=$(rpmspec -q --srpm --queryformat "%{version}" ${SPEC})

spectool -g ${SPEC}

tar -xzf ${NAME}-${VERSION}.tar.gz

pushd ${NAME}-${VERSION}
cargo vendor --versioned-dirs vendor > ../vendor.toml
tar -Jcf ../${NAME}-${VERSION}-vendor.tar.xz vendor/
popd

rm -rf ${NAME}-${VERSION}/

