#!/usr/bin/env bash
set -e
set -x
. /etc/profile

WORKDIR=$PWD
UTILS_VER=$(utilsVersion 2> /dev/null || echo "")

# cd $WORKDIR
# 
# CORS_DOCKERFILE=./cors-anywhere/Dockerfile
# 
# REF_GITHUB_BRNACH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD || echo "")
# ( [ -z "$REF_GITHUB_BRNACH" ] || [ "${REF_GITHUB_BRNACH,,}" == "head" ] ) && REF_GITHUB_BRNACH="${SOURCE_BRANCH}"
# 
# rm -fv $CORS_DOCKERFILE
# REF_GITHUB_BRNACH=${REF_GITHUB_BRNACH//"/"/"\/"}
# sed "s/\${REF_GITHUB_BRNACH}/$REF_GITHUB_BRNACH/" ${CORS_DOCKERFILE}.src > $CORS_DOCKERFILE