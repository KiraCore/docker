#!/usr/bin/env bash
exec 2>&1
set -x
set -e

apt-get update -y
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    software-properties-common curl wget git nginx apt-transport-https

CDHELPER_VERSION="v0.6.51"
SEKAI_VERSION="v0.1.23-rc.3"
INTERX_VERSION="v0.4.1-rc.5"
TOOLS_VERSION="v0.0.8.0"

cd $KIRA_BIN

wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/kira-utils.sh" -O ./utils.sh && \
    FILE_HASH=$(sha256sum ./utils.sh | awk '{ print $1 }' | xargs || echo -n "") && \
    [ "$FILE_HASH" == "1cfb806eec03956319668b0a4f02f2fcc956ed9800070cda1870decfe2e6206e" ] && \
    chmod -v 555 ./utils.sh && ./utils.sh utilsSetup ./utils.sh "/var/kiraglob" && . /etc/profile

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

safeWget ./sekaid.deb \
 "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-linux-amd64.deb" \
  "dfa9d40b0b28c4fa83714f4dc4f44f70f36e3b1fb444dfab30c1aa764e22646d" && \
  dpkg-deb -x ./sekaid.deb ./sekaid-amd64
safeWget ./sekaid.deb \
 "https://github.com/KiraCore/sekai/releases/download/$SEKAI_VERSION/sekai-linux-arm64.deb" \
  "43cd256db392a73ef9173cd8626b1c603bf44189d95b7fdaab64211af1c5f1fc" && \
  dpkg-deb -x ./sekaid.deb ./sekaid-arm64

safeWget ./interx.deb \
 "https://github.com/KiraCore/interx/releases/download/$INTERX_VERSION/interx-linux-arm64.deb" \
  "af63eac487dc78c3c02a75d655c1c0acd1fd951c76d2e7acfa71e8af4a590928" && \
  dpkg-deb -x ./interx.deb ./interx-arm64
safeWget ./interx.deb \
 "https://github.com/KiraCore/interx/releases/download/$INTERX_VERSION/interx-linux-amd64.deb" \
  "f93c4b8cf80ebb5d717bc52662924b897a51fb5b7dd2158f78e143b9fe6cafda" && \
  dpkg-deb -x ./interx.deb ./interx-amd64

safeWget ./tmconnect.deb \
 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmconnect-linux-amd64.deb" \
  "983bec70a9736c866db734cbe84d644c041174fec009946cbe4fb3bc3813cb18" && \
  dpkg-deb -x ./tmconnect.deb ./tmconnect-amd64
safeWget ./tmconnect.deb \
 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmconnect-linux-arm64.deb" \
  "e3820a4f02ea203c89827e145d6393f5d9b62b093867b75660ebdb8c5aa98e00" && \
  dpkg-deb -x ./tmconnect.deb ./tmconnect-arm64

safeWget ./validator-key-gen.deb \
 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/validator-key-gen-linux-amd64.deb" \
  "ebfb5e4835fd39f55401544b606d9c80c513ea820f37385dbe542e83d10adb57" && \
  dpkg-deb -x ./validator-key-gen.deb ./validator-key-gen-amd64
safeWget ./validator-key-gen.deb \
 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/validator-key-gen-linux-arm64.deb" \
  "b2e29e3ed2dae5b6915475411850399acebea1ee00a94c6a6e7cdb66f985cde9" && \
  dpkg-deb -x ./validator-key-gen.deb ./validator-key-gen-arm64

safeWget ./tmkms-key-import-amd64 \
 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmkms-key-import-linux-amd64" \
  "7214d252bcbee9cce0c5e0878e37c973427e432349baee0ce3a702f1cf4c6e6d"
safeWget ./tmkms-key-import-arm64 \
 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/tmkms-key-import-linux-arm64" \
  "e05550691546e571f7ea952618ed5bd753c96ab5db4e6e9f2e57cbdb3e751bef"

crossenvLink "$KIRA_BIN/CDHelper-<arch>/CDHelper" "/usr/local/bin/CDhelper"
crossenvLink "$KIRA_BIN/sekaid-<arch>/bin/sekaid" "/usr/local/bin/sekaid"
crossenvLink "$KIRA_BIN/interx-<arch>/bin/interx" "/usr/local/bin/interx"
crossenvLink "$KIRA_BIN/tmconnect-<arch>/bin/tmconnect" "/usr/local/bin/tmconnect"
crossenvLink "$KIRA_BIN/tmkms-key-import-<arch>" "/usr/local/bin/tmkms-key-import"
crossenvLink "$KIRA_BIN/validator-key-gen-<arch>/bin/validator-key-gen" "/usr/local/bin/validator-key-gen"

echoInfo "Installed CDHelper $(CDhelper version)"
echoInfo "Installed sekaid $(sekaid version)"
echoInfo "Installed interx $(interx version)"
echoInfo "Installed tmconnect $(tmconnect version)"
echoInfo "Installed validator-key-gen $(validator-key-gen --version)"
echoInfo "Installed tmkms-key-import $(tmkms-key-import version)"

