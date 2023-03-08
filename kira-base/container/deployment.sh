#!/usr/bin/env bash
exec 2>&1
set -x
set -e

apt-get update -y
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    software-properties-common curl wget git nginx apt-transport-https

BTC_VERSION="24.0.1"
SEKAI_VERSION="v0.3.12.36"
INTERX_VERSION="v0.4.26"
TOOLS_VERSION="v0.3.19"
COSIGN_VERSION="v1.13.1"

BTC_CHECKUSMS="37d7660f0277301744e96426bbb001d2206b8d4505385dfdeedf50c09aaaef60,49df6e444515d457ea0b885d66f521f2a26ca92ccf73d5296082e633544253bf,90ed59e86bfda1256f4b4cad8cc1dd77ee0efec2492bcb5af61402709288b62c,06f4c78271a77752ba5990d60d81b1751507f77efda1e5981b4e92fd4d9969fb,078f96b1e92895009c798ab827fb3fde5f6719eee886bd0c0e93acab18ea4865,0b48b9e69b30037b41a1e6b78fb7cbcc48c7ad627908c99686e81f3802454609,12d4ad6dfab4767d460d73307e56d13c72997e114fad4f274650f95560f5f2ff,6b163cef7de4beb07b8cb3347095e0d76a584019b1891135cd1268a1f05b9d88"

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
 chmod +x ./$FILE_NAME && ./$FILE_NAME bashUtilsSetup "$GLOBAL_COMMON"
 
source $FILE_NAME
echoInfo "INFO: Installed bash-utils $(bash-utils bashUtilsVersion)"

echoInfo "INFO: APT Update, Update, Intall & Install dependencies..."
apt-get update -y --fix-missing
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    file build-essential hashdeep make tar unzip zip p7zip-full curl iputils-ping nano jq python python3 python3-pip \
    bash lsof bc dnsutils psmisc netcat coreutils binutils

BIN_DEST="/usr/local/bin/sekaid" && \
  safeWget ./sekaid.deb "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./sekaid.deb ./sekaid && cp -fv "$KIRA_BIN/sekaid/bin/sekaid" $BIN_DEST && chmod +x $BIN_DEST

BIN_DEST="/usr/local/bin/sekai-utils.sh" && \
  safeWget ./sekai-utils.sh "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-utils.sh" \
  "$KIRA_COSIGN_PUB" && chmod +x ./sekai-utils.sh && ./sekai-utils.sh sekaiUtilsSetup && chmod +x $BIN_DEST && . /etc/profile

FILE=/usr/local/bin/sekai-env.sh && \
safeWget $FILE "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-env.sh" \
  "$KIRA_COSIGN_PUB" && chmod +x $FILE && echo "source $FILE" >> /etc/profile && . /etc/profile

BIN_DEST="/usr/local/bin/interxd" && \
safeWget ./interx.deb "https://github.com/KiraCore/interx/releases/download/$INTERX_VERSION/interx-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./interx.deb ./interx && cp -fv "$KIRA_BIN/interx/bin/interx" $BIN_DEST && chmod +x $BIN_DEST

BIN_DEST="/usr/local/bin/tmconnect" && \
  safeWget ./tmconnect.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmconnect-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./tmconnect.deb ./tmconnect && cp -fv "$KIRA_BIN/tmconnect/bin/tmconnect" $BIN_DEST && chmod +x $BIN_DEST

BIN_DEST="/usr/local/bin/validator-key-gen" && \
  safeWget ./validator-key-gen.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/validator-key-gen-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./validator-key-gen.deb ./validator-key-gen && \
   cp -fv "$KIRA_BIN/validator-key-gen/bin/validator-key-gen" $BIN_DEST && chmod +x $BIN_DEST

BIN_DEST="/usr/local/bin/tmkms-key-import" && \
  safeWget ./tmkms-key-import "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmkms-key-import-$(getPlatform)-$(getArch)" \
  "$KIRA_COSIGN_PUB" && cp -fv "$KIRA_BIN/tmkms-key-import" $BIN_DEST && chmod +x $BIN_DEST

BIN_DEST="/usr/local/bin/bip39gen" && \
  safeWget ./bip39gen.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/bip39gen-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./bip39gen.deb ./bip39gen && cp -fv "$KIRA_BIN/bip39gen/bin/bip39gen" $BIN_DEST && chmod +x $BIN_DEST

BIN_DEST="/usr/local/bin/ipfs-api" && \
  safeWget ./ipfs-api.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/ipfs-api-$(getPlatform)-$(getArch).deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./ipfs-api.deb ./ipfs-api && cp -fv "$KIRA_BIN/ipfs-api/bin/ipfs-api" $BIN_DEST && chmod +x $BIN_DEST

safeWget ./bitcoin-core.tar.gz "https://bitcoincore.org/bin/bitcoin-core-${BTC_VERSION}/bitcoin-${BTC_VERSION}-$(uname -m)-$(getPlatform)-gnu.tar.gz" \
 "$BTC_CHECKUSMS" && BTC_DIR=/opt/bitcoin && rm -rfv $BTC_DIR && mkdir $BTC_DIR && tar -xzvf ./bitcoin-core.tar.gz -C $BTC_DIR --strip-components=1 --exclude=*-qt && \
  setGlobPath "$BTC_DIR/bin" && chmod +x $BTC_DIR

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

