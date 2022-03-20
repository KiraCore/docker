#!/usr/bin/env bash
set -e
set -x
. /etc/profile

RELEASE_VER="$(grep -Fn -m 1 'Release: ' ./RELEASE.md | rev | cut -d ":" -f1 | rev | xargs | tr -dc '[:alnum:]\-\.' || echo '' | xargs)"

DOCKERFILE=./cors-anywhere/Dockerfile
REF_GITHUB_BRNACH=${RELEASE_VER//"/"/"\/"}

sed -i"" "s/\${REF_GITHUB_BRNACH}/$REF_GITHUB_BRNACH/" ${DOCKERFILE}
