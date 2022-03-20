#!/usr/bin/env bash
exec 2>&1
set -e
set -x

TOOLS_VERSION="v0.0.8.0"

echo "Starting core dependency build..."
apt-get update -y
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    software-properties-common curl wget git nginx apt-transport-https jq

echo "INFO: Installing kira-utils..."
wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/kira-utils.sh" -O ./utils.sh && \
    FILE_HASH=$(sha256sum ./utils.sh | awk '{ print $1 }' | xargs || echo -n "") && \
    [ "$FILE_HASH" == "1cfb806eec03956319668b0a4f02f2fcc956ed9800070cda1870decfe2e6206e" ] && \
    chmod -v 555 ./utils.sh && ./utils.sh utilsSetup ./utils.sh "/var/kiraglob" && . /etc/profile

echoInfo "INFO: Updating dpeendecies (2)..."
apt-get update -y

echoInfo "INFO: Installing core dpeendecies..."
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    file build-essential net-tools hashdeep make ca-certificates p7zip-full lsof libglu1-mesa bash gnupg \
    nodejs node-gyp python python3 python3-pip tar unzip xz-utils yarn zip protobuf-compiler golang-goprotobuf-dev \
    golang-grpc-gateway golang-github-grpc-ecosystem-grpc-gateway-dev clang cmake gcc g++ pkg-config libudev-dev \
    libusb-1.0-0-dev curl iputils-ping nano openssl dos2unix

echoInfo "INFO: Updating dpeendecies (3)..."
apt update -y
apt install -y bc dnsutils psmisc netcat nodejs npm

npm install cors-anywhere
cd /node_modules/cors-anywhere
npm install

