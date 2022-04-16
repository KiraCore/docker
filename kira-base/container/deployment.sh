#!/usr/bin/env bash
exec 2>&1
set -x
set -e

apt-get update -y
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    software-properties-common curl wget git nginx apt-transport-https

CDHELPER_VERSION="v0.6.51"
SEKAI_VERSION="v0.1.26-rc.11"
INTERX_VERSION="v0.4.5-rc.4"
TOOLS_VERSION="v0.1.0.7"
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

FILE_NAME="bash-utils.sh" && \
 wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/${FILE_NAME}" -O ./$FILE_NAME && \
 wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/${FILE_NAME}.sig" -O ./${FILE_NAME}.sig && \
 cosign verify-blob --key="$KIRA_COSIGN_PUB" --signature=./${FILE_NAME}.sig ./$FILE_NAME && \
 chmod -v 555 ./$FILE_NAME && ./$FILE_NAME bashUtilsSetup "/var/kiraglob" && . /etc/profile && \
 echoInfo "INFO: Installed bash-utils $(bash-utils bashUtilsVersion)"

echoInfo "INFO: APT Update, Update and Intall..."
apt-get update -y --fix-missing
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    file build-essential hashdeep make tar unzip zip p7zip-full curl iputils-ping nano jq python python3 python3-pip \
    bash lsof bc dnsutils psmisc netcat coreutils binutils

safeWget ./cdhelper.zip \
 "https://github.com/asmodat/CDHelper/releases/download/$CDHELPER_VERSION/CDHelper-linux-arm64.zip" \
  "c2e40c7143f4097c59676f037ac6eaec68761d965bd958889299ab32f1bed6b3" && \
  unzip ./cdhelper.zip -d "CDHelper-arm64"
safeWget ./cdhelper.zip \
 "https://github.com/asmodat/CDHelper/releases/download/$CDHELPER_VERSION/CDHelper-linux-x64.zip" \
  "082e05210f93036e0008658b6c6bd37ab055bac919865015124a0d72e18a45b7" && \
  unzip ./cdhelper.zip -d "CDHelper-amd64"

safeWget ./sekaid.deb "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-linux-amd64.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./sekaid.deb ./sekaid-amd64
safeWget ./sekaid.deb "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-linux-arm64.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./sekaid.deb ./sekaid-arm64

safeWget ./sekai-utils.sh "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-utils.sh" \
  "$KIRA_COSIGN_PUB" && chmod +x ./sekai-utils.sh && ./sekai-utils.sh sekaiUtilsSetup && . /etc/profile
FILE=/usr/local/bin/sekai-env.sh && \
safeWget $FILE "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-env.sh" \
  "$KIRA_COSIGN_PUB" && chmod +x $FILE && echo "source $FILE" >> /etc/profile && . /etc/profile

safeWget ./interx.deb "https://github.com/KiraCore/interx/releases/download/$INTERX_VERSION/interx-linux-amd64.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./interx.deb ./interx-amd64
safeWget ./interx.deb "https://github.com/KiraCore/interx/releases/download/$INTERX_VERSION/interx-linux-arm64.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./interx.deb ./interx-arm64

safeWget ./tmconnect.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmconnect-linux-amd64.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./tmconnect.deb ./tmconnect-amd64
safeWget ./tmconnect.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmconnect-linux-arm64.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./tmconnect.deb ./tmconnect-arm64

safeWget ./validator-key-gen.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/validator-key-gen-linux-amd64.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./validator-key-gen.deb ./validator-key-gen-amd64
safeWget ./validator-key-gen.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/validator-key-gen-linux-arm64.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./validator-key-gen.deb ./validator-key-gen-arm64

# safeWget ./tmkms-key-import-amd64 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmkms-key-import-linux-amd64" \
#   "$KIRA_COSIGN_PUB"
# safeWget ./tmkms-key-import-arm64 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmkms-key-import-linux-arm64" \
#   "$KIRA_COSIGN_PUB"

safeWget ./bip39gen.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/bip39gen-linux-amd64.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./bip39gen.deb ./bip39gen-amd64
safeWget ./bip39gen.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/bip39gen-linux-arm64.deb" \
  "$KIRA_COSIGN_PUB" && dpkg-deb -x ./bip39gen.deb ./bip39gen-arm64

crossenvLink "$KIRA_BIN/CDHelper-<arch>/CDHelper" "/usr/local/bin/CDhelper"
crossenvLink "$KIRA_BIN/sekaid-<arch>/bin/sekaid" "/usr/local/bin/sekaid"
crossenvLink "$KIRA_BIN/interx-<arch>/bin/interx" "/usr/local/bin/interx"
crossenvLink "$KIRA_BIN/tmconnect-<arch>/bin/tmconnect" "/usr/local/bin/tmconnect"
# crossenvLink "$KIRA_BIN/tmkms-key-import-<arch>" "/usr/local/bin/tmkms-key-import"
crossenvLink "$KIRA_BIN/validator-key-gen-<arch>/bin/validator-key-gen" "/usr/local/bin/validator-key-gen"
crossenvLink "$KIRA_BIN/bip39gen-<arch>/bin/bip39gen" "/usr/local/bin/bip39gen"

echoInfo "INFO: Installed CDHelper: " && CDhelper version
echoInfo "INFO: Installed bash-utils: " && bashUtilsVersion
echoInfo "INFO: Installed sekai-utils: " && sekaiUtilsVersion
echoInfo "INFO: Installed sekaid: " && sekaid version
echoInfo "INFO: Installed interx: " && interx version
echoInfo "INFO: Installed tmconnect: " && tmconnect version
echoInfo "INFO: Installed validator-key-gen: " && validator-key-gen --version
echoInfo "INFO: Installed tmkms-key-import: " && tmkms-key-import version
echoInfo "INFO: Installed bip39gen: " && bip39gen version
