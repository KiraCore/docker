#!/bin/bash

exec 2>&1
set -e
set -x

apt-get update -y
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    software-properties-common curl wget git nginx apt-transport-https

echo "APT Update, Update and Intall..."
apt-get update -y --fix-missing
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    file build-essential net-tools hashdeep make \
    nodejs \
    node-gyp \
    tar \
    unzip \
    xz-utils \
    yarn \
    zip \
    protobuf-compiler \
    golang-goprotobuf-dev \
    golang-grpc-gateway \
    golang-github-grpc-ecosystem-grpc-gateway-dev \
    clang \
    cmake \
    gcc \
    g++ \
    pkg-config \
    libudev-dev \
    libusb-1.0-0-dev \
    curl \
    iputils-ping \
    nano \
    jq \
    openssl

apt update -y
apt install -y bc dnsutils psmisc netcat nodejs npm

ARCHITECTURE=$(uname -m)
OS_VERSION=$(uname) && OS_VERSION="${OS_VERSION,,}"
GO_VERSION="1.17.8"
CDHELPER_VERSION="v0.6.51"
FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="2.10.3-$FLUTTER_CHANNEL"
DART_CHANNEL_PATH="stable/release"
DART_VERSION="2.16.1"
KIRA_UTILS_BRANCH="v0.0.2"

cd /tmp && rm -fv ./i.sh && \
 wget https://raw.githubusercontent.com/KiraCore/tools/$KIRA_UTILS_BRANCH/bash-utils/install.sh -O ./i.sh && \
 chmod 555 ./i.sh && ./i.sh "$KIRA_UTILS_BRANCH" "/var/kiraglob" && . /etc/profile && loadGlobEnvs

if [[ "${ARCHITECTURE,,}" == *"arm"* ]] || [[ "${ARCHITECTURE,,}" == *"aarch"* ]] ; then
    GOLANG_ARCH="arm64"
    DART_ARCH="arm64"
    CDHELPER_ARCH="arm64"
    GO_EXPECTED_HASH="57a9171682e297df1a5bd287be056ed0280195ad079af90af16dcad4f64710cb"
    DART_EXPECTED_HASH="de9d1c528367f83bbd192bd565af5b7d9d48f76f79baa4c0e4cf64723e3fb8be"
    FLUTTER_EXPECTED_HASH="7e2a28d14d7356a5bbfe516f8a7c9fc0353f85fe69e5cf6af22be2c7c8b45566"
    CDHELPER_EXPECTED_HASH="c2e40c7143f4097c59676f037ac6eaec68761d965bd958889299ab32f1bed6b3"
else
    GOLANG_ARCH="amd64"
    DART_ARCH="x64"
    CDHELPER_ARCH="x64"
    GO_EXPECTED_HASH="980e65a863377e69fd9b67df9d8395fd8e93858e7a24c9f55803421e453f4f99"
    DART_EXPECTED_HASH="3cc63a0c21500bc5eb9671733843dcc20040b39fdc02f35defcf7af59f88d459"
    FLUTTER_EXPECTED_HASH="7e2a28d14d7356a5bbfe516f8a7c9fc0353f85fe69e5cf6af22be2c7c8b45566"
    CDHELPER_EXPECTED_HASH="082e05210f93036e0008658b6c6bd37ab055bac919865015124a0d72e18a45b7"
fi

GO_TAR="go$GO_VERSION.${OS_VERSION}-$GOLANG_ARCH.tar.gz"
FLUTTER_TAR="flutter_${OS_VERSION}_$FLUTTER_VERSION.tar.xz"
DART_ZIP="dartsdk-${OS_VERSION}-$DART_ARCH-release.zip"
CDHELPER_ZIP="CDHelper-${OS_VERSION}-$CDHELPER_ARCH.zip"

echoInfo "INFO: Installing CDHelper tool"
cd /tmp && rm -f -v ./$CDHELPER_ZIP && \
 wget "https://github.com/asmodat/CDHelper/releases/download/$CDHELPER_VERSION/$CDHELPER_ZIP" && \
 FILE_HASH=$(sha256 ./$CDHELPER_ZIP) && [ "$FILE_HASH" != "$CDHELPER_EXPECTED_HASH" ] && \
 echoNErr "\nDANGER: Failed to check integrity hash of the CDHelper tool !!!\nERROR: Expected hash: $CDHELPER_EXPECTED_HASH, but got $FILE_HASH\n" && \
 sleep 2 && exit 1
 
INSTALL_DIR="/usr/local/bin/CDHelper"
rm -rfv $INSTALL_DIR
mkdir -pv $INSTALL_DIR
unzip $CDHELPER_ZIP -d $INSTALL_DIR
chmod -R -v 555 $INSTALL_DIR
 
ls -l /bin/CDHelper || echo "INFO: Symlink not found"
rm /bin/CDHelper || echo "INFO: Failed to remove old symlink"
ln -s $INSTALL_DIR/CDHelper /bin/CDHelper || echo "INFO: CDHelper symlink already exists" 
CDHelper version

echoInfo "INFO: Installing latest go $GOLANG_ARCH version $GO_VERSION https://golang.org/doc/install ..."
cd /tmp && wget https://dl.google.com/go/$GO_TAR && \
 FILE_HASH=$(sha256 ./$GO_TAR) && [ "$FILE_HASH" != "$GO_EXPECTED_HASH" ] && \
 echoNErr "\nDANGER: Failed to check integrity hash of the go tool !!!\nERROR: Expected hash: $GO_EXPECTED_HASH, but got $FILE_HASH\n" && \
 sleep 2 && exit 1

tar -C /usr/local -xvf $GO_TAR &>/dev/null

echoInfo "INFO: Setting up essential flutter dependencies..."
cd /tmp && wget https://storage.googleapis.com/flutter_infra_release/releases/$FLUTTER_CHANNEL/${OS_VERSION}/$FLUTTER_TAR && \
 FILE_HASH=$(sha256 ./$FLUTTER_TAR) && [ "$FILE_HASH" != "$FLUTTER_EXPECTED_HASH" ] && \
 echoNErr "\nDANGER: Failed to check integrity hash of the Flutter tool !!!\nERROR: Expected hash: $FLUTTER_EXPECTED_HASH, but got $FILE_HASH\n" && \
 sleep 2 && exit 1

mkdir -p /usr/lib # make sure flutter root directory exists
tar -C /usr/lib -xvf ./$FLUTTER_TAR

echoInfo "INFO: Setting up essential dart dependencies..."
FLUTTER_CACHE=$FLUTTERROOT/bin/cache
rm -rfv $FLUTTER_CACHE/dart-sdk
mkdir -p $FLUTTER_CACHE # make sure flutter cache direcotry exists & essential files which prevent automatic update
touch $FLUTTER_CACHE/.dartignore
touch $FLUTTER_CACHE/engine-dart-sdk.stamp

echoInfo "INFO: Installing latest dart $DART_ARCH version $DART_VERSION https://dart.dev/get-dart/archive ..."
cd /tmp && wget https://storage.googleapis.com/dart-archive/channels/$DART_CHANNEL_PATH/$DART_VERSION/sdk/$DART_ZIP && \
FILE_HASH=$(sha256 ./$DART_ZIP) && [ "$FILE_HASH" != "$DART_EXPECTED_HASH" ] && \
 echoNErr "\nDANGER: Failed to check integrity hash of the Dart tool !!!\nERROR: Expected hash: $DART_EXPECTED_HASH, but got $FILE_HASH\n" && \
 sleep 2 && exit 1

unzip ./$DART_ZIP -d $FLUTTER_CACHE

flutter config --enable-web
flutter doctor

rm -fv $DART_ZIP $FLUTTER_TAR