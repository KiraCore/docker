#!/usr/bin/env bash
exec 2>&1
set -x
set -e

apt-get update -y
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    software-properties-common curl wget git nginx apt-transport-https

BTC_VERSION="23.0"
SEKAI_VERSION="v0.3.1.23"
INTERX_VERSION="v0.4.18"
TOOLS_VERSION="v0.2.20"
COSIGN_VERSION="v1.7.2"

BTC_CHECKUSMS="06f4c78271a77752ba5990d60d81b1751507f77efda1e5981b4e92fd4d9969fb,952c574366aff76f6d6ad1c9ee45a361d64fa04155e973e926dfe7e26f9703a3,2cca490c1f2842884a3c5b0606f179f9f937177da4eadd628e3f7fd7e25d26d0"

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

echoInfo "INFO: APT Update, Update, Intall & Install dependencies..."
apt-get update -y --fix-missing
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    file build-essential hashdeep make tar unzip zip p7zip-full curl iputils-ping nano jq python python3 python3-pip \
    bash lsof bc dnsutils psmisc netcat coreutils binutils

BIN_DEST="/usr/local/bin/sekaid" && \
  safeWget ./sekaid.deb "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./sekaid.deb ./sekaid && cp -fv "$KIRA_BIN/sekaid/bin/sekaid" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/sekai-utils.sh" && \
  safeWget ./sekai-utils.sh "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-utils.sh" \
  "$KIRA_COSIGN_PUB" && chmod -v 755 ./sekai-utils.sh && ./sekai-utils.sh sekaiUtilsSetup && chmod -v 755 $BIN_DEST && . /etc/profile

FILE=/usr/local/bin/sekai-env.sh && \
safeWget $FILE "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-env.sh" \
  "$KIRA_COSIGN_PUB" && chmod -v 755 $FILE && echo "source $FILE" >> /etc/profile && . /etc/profile

BIN_DEST="/usr/local/bin/interxd" && \
safeWget ./interx.deb "https://github.com/KiraCore/interx/releases/download/$INTERX_VERSION/interx-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./interx.deb ./interx && cp -fv "$KIRA_BIN/interx/bin/interx" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/tmconnect" && \
  safeWget ./tmconnect.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmconnect-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./tmconnect.deb ./tmconnect && cp -fv "$KIRA_BIN/tmconnect/bin/tmconnect" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/validator-key-gen" && \
  safeWget ./validator-key-gen.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/validator-key-gen-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./validator-key-gen.deb ./validator-key-gen && \
   cp -fv "$KIRA_BIN/validator-key-gen/bin/validator-key-gen" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/tmkms-key-import" && \
  safeWget ./tmkms-key-import "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmkms-key-import-$(getPlatform)-$(getArch)" \
  "$KIRA_COSIGN_PUB" && cp -fv "$KIRA_BIN/tmkms-key-import" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/bip39gen" && \
  safeWget ./bip39gen.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/bip39gen-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./bip39gen.deb ./bip39gen && cp -fv "$KIRA_BIN/bip39gen/bin/bip39gen" $BIN_DEST && chmod -v 755 $BIN_DEST

BIN_DEST="/usr/local/bin/ipfs-api" && \
  safeWget ./ipfs-api.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/ipfs-api-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./ipfs-api.deb ./ipfs-api && cp -fv "$KIRA_BIN/ipfs-api/bin/ipfs-api" $BIN_DEST && chmod -v 755 $BIN_DEST

safeWget ./bitcoin-core.tar.gz "https://bitcoincore.org/bin/bitcoin-core-${BTC_VERSION}/bitcoin-${BTC_VERSION}-$(uname -m)-$(getPlatform)-gnu.tar.gz" \
 "$BTC_CHECKUSMS" && BTC_DIR=/opt/bitcoin && rm -rfv $BTC_DIR && mkdir $BTC_DIR && tar -xzvf ./bitcoin-core.tar.gz -C $BTC_DIR --strip-components=1 --exclude=*-qt && \
  setGlobPath "$BTC_DIR/bin" && chmod -Rv 755 $BTC_DIR

loadGlobEnvs

echoInfo "INFO: Cleanup downloads..." 
rm -rfv /tmp/downloads

echoInfo "INFO: Installed bash-utils: " && bashUtilsVersion
echoInfo "INFO: Installed sekai-utils: " && sekaiUtilsVersion
echoInfo "INFO: Installed sekaid: " && sekaid version
echoInfo "INFO: Installed interxd: " && interxd version
echoInfo "INFO: Installed tmconnect: " && tmconnect version
echoInfo "INFO: Installed validator-key-gen: " && validator-key-gen --version
echoInfo "INFO: Installed tmkms-key-import: " && tmkms-key-import version
echoInfo "INFO: Installed bip39gen: " && bip39gen version
echoInfo "INFO: Installed ipfs-api: " && ipfs-api version
echoInfo "INFO: Installed bitcoind: " && bitcoind --version

