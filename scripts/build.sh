#!/usr/bin/env bash
set -e
set -x
. /etc/profile

WORKDIR=$PWD
UTILS_VER=$(utilsVersion 2> /dev/null || echo "")

# Installing utils is essential to simplify the setup steps
if [[ $(versionToNumber "$UTILS_VER" || echo "0") -lt $(versionToNumber "v0.0.15" || echo "1") ]] ; then
    echo "INFO: KIRA utils were NOT installed on the system, setting up..." && sleep 2
    KIRA_UTILS_BRANCH="v0.0.3" && cd /tmp && rm -fv ./i.sh && \
    wget https://raw.githubusercontent.com/KiraCore/tools/$KIRA_UTILS_BRANCH/bash-utils/install.sh -O ./i.sh && \
    chmod 555 ./i.sh && ./i.sh "$KIRA_UTILS_BRANCH" "/var/kiraglob" && . /etc/profile && loadGlobEnvs
else
    echoInfo "INFO: KIRA utils are up to date, latest version $UTILS_VER"
fi

cd $WORKDIR

CORS_DOCKERFILE=./cors-anywhere/Dockerfile

REF_GITHUB_BRNACH=$(git rev-parse --abbrev-ref HEAD)

rm -fv $CORS_DOCKERFILE
REF_GITHUB_BRNACH=${REF_GITHUB_BRNACH//"/"/"\/"}
sed "s/\${REF_GITHUB_BRNACH}/$REF_GITHUB_BRNACH/" ${CORS_DOCKERFILE}.src > $CORS_DOCKERFILE