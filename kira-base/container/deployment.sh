#!/usr/bin/env bash
exec 2>&1
set -x
set -e

apt-get update -y
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    software-properties-common curl wget git nginx apt-transport-https

CDHELPER_VERSION="v0.6.51"
SEKAI_VERSION="v0.2.1-rc.15"
INTERX_VERSION="v0.4.10"
TOOLS_VERSION="v0.2.2"
COSIGN_VERSION="v1.7.2"

cd $KIRA_BIN

echo "INFO: Installing cosign"
if [[ "$(uname -m)" == *"ar"* ]] ; then ARCH="arm64"; else ARCH="amd64" ; fi && echo $ARCH && \
PLATFORM=$(uname) && FILE_NAME=$(echo "cosign-${PLATFORM}-${ARCH}" | tr '[:upper:]' '[:lower:]') && \
 wget https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/$FILE_NAME && chmod +x -v ./$FILE_NAME && \
 mv -fv ./$FILE_NAME /usr/local/bin/cosign && cosign version

cat > $KIRA_COSIGN_PUB << EOL
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE/IrzBQYeMwvKa44/DF/HB7XDpnE+
f+mU9F/Qbfq25bBWV2+NlYMJv3KvKHNtu3Jknt6yizZjUV4b8WGfKBzFYw==
-----END PUBLIC KEY-----
EOL

chmod -v 444 $KIRA_COSIGN_PUB

echo "Creating kira user..."
USERNAME=kira
useradd -s /bin/bash -d /home/kira -m -G sudo $USERNAME
usermod -aG sudo $USERNAME

echo "INFO: Installing bash utils..."

FILE_NAME="bash-utils.sh" && \
 wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/${FILE_NAME}" -O ./$FILE_NAME && \
 wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/${FILE_NAME}.sig" -O ./${FILE_NAME}.sig && \
 cosign verify-blob --key="$KIRA_COSIGN_PUB" --signature=./${FILE_NAME}.sig ./$FILE_NAME && \
 chmod -v 755 ./$FILE_NAME && ./$FILE_NAME bashUtilsSetup "$GLOBAL_COMMON"
 
source $FILE_NAME

echoInfo "INFO: Installed bash-utils $(bash-utils bashUtilsVersion)"

PLATFORM="$(getPlatform)"
ARCHITECURE=$(getArch)

echoInfo "INFO: APT Update, Update, Intall & Install dependencies..."
apt-get update -y --fix-missing
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    file build-essential hashdeep make tar unzip zip p7zip-full curl iputils-ping nano jq python python3 python3-pip \
    bash lsof bc dnsutils psmisc netcat coreutils binutils

BIN_DEST="/usr/local/bin/CDHelper" && \
  safeWget ./cdhelper.zip "https://github.com/asmodat/CDHelper/releases/download/$CDHELPER_VERSION/CDHelper-linux-${ARCHITECURE}.zip" \
  "082e05210f93036e0008658b6c6bd37ab055bac919865015124a0d72e18a45b7,c2e40c7143f4097c59676f037ac6eaec68761d965bd958889299ab32f1bed6b3" && \
  unzip -o ./cdhelper.zip -d "CDHelper" && cp -rfv "$KIRA_BIN/CDHelper" "$(dirname $BIN_DEST)" && chmod -Rv 755 $BIN_DEST && setGlobPath $BIN_DEST

BIN_DEST="/usr/local/bin/sekaid" && \
  safeWget ./sekaid.deb "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-linux-${ARCHITECURE}.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./sekaid.deb ./sekaid && cp -fv "$KIRA_BIN/sekaid/bin/sekaid" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/sekai-utils.sh" && \
  safeWget ./sekai-utils.sh "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-utils.sh" \
  "$KIRA_COSIGN_PUB" && chmod -v 755 ./sekai-utils.sh && ./sekai-utils.sh sekaiUtilsSetup && chmod -v 755 $BIN_DEST && . /etc/profile

FILE=/usr/local/bin/sekai-env.sh && \
safeWget $FILE "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-env.sh" \
  "$KIRA_COSIGN_PUB" && chmod -v 755 $FILE && echo "source $FILE" >> /etc/profile && . /etc/profile

BIN_DEST="/usr/local/bin/interxd" && \
safeWget ./interx.deb "https://github.com/KiraCore/interx/releases/download/$INTERX_VERSION/interx-linux-${ARCHITECURE}.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./interx.deb ./interx && cp -fv "$KIRA_BIN/interx/bin/interx" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/tmconnect" && \
  safeWget ./tmconnect.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmconnect-linux-${ARCHITECURE}.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./tmconnect.deb ./tmconnect && cp -fv "$KIRA_BIN/tmconnect/bin/tmconnect" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/validator-key-gen" && \
  safeWget ./validator-key-gen.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/validator-key-gen-linux-${ARCHITECURE}.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./validator-key-gen.deb ./validator-key-gen && \
   cp -fv "$KIRA_BIN/validator-key-gen/bin/validator-key-gen" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/tmkms-key-import" && \
  safeWget ./tmkms-key-import "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmkms-key-import-linux-${ARCHITECURE}" \
  "$KIRA_COSIGN_PUB" && cp -fv "$KIRA_BIN/tmkms-key-import" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/bip39gen" && \
  safeWget ./bip39gen.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/bip39gen-linux-${ARCHITECURE}.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./bip39gen.deb ./bip39gen && cp -fv "$KIRA_BIN/bip39gen/bin/bip39gen" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/ipfs-api" && \
  safeWget ./ipfs-api.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/ipfs-api-linux-${ARCHITECURE}.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./ipfs-api.deb ./ipfs-api && cp -fv "$KIRA_BIN/ipfs-api/bin/ipfs-api" $BIN_DEST && chmod -v 755 $BIN_DEST

loadGlobEnvs

echoInfo "INFO: Installed CDHelper: " && CDHelper version
echoInfo "INFO: Installed bash-utils: " && bashUtilsVersion
echoInfo "INFO: Installed sekai-utils: " && sekaiUtilsVersion
echoInfo "INFO: Installed sekaid: " && sekaid version
echoInfo "INFO: Installed interxd: " && interxd version
echoInfo "INFO: Installed tmconnect: " && tmconnect version
echoInfo "INFO: Installed validator-key-gen: " && validator-key-gen --version
echoInfo "INFO: Installed tmkms-key-import: " && tmkms-key-import version
echoInfo "INFO: Installed bip39gen: " && bip39gen version
echoInfo "INFO: Installed ipfs-api: " && ipfs-api version
