#!/usr/bin/env bash
set -e
set -x
. /etc/profile

RELEASE_VER=$(./scripts/version.sh)

DOCKERFILE=./cors-anywhere/Dockerfile
REF_GITHUB_BRNACH=${RELEASE_VER//"/"/"\/"}

sed -i"" "s/\${REF_GITHUB_BRNACH}/$REF_GITHUB_BRNACH/" ${DOCKERFILE}
