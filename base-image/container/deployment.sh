#!/usr/bin/env bash
exec 2>&1
set -e
set -x

# define versions of the software to install manually
ARCHITECTURE=$(uname -m)
OS_VERSION=$(uname) && OS_VERSION="${OS_VERSION,,}"
GO_VERSION="1.17.8"
CDHELPER_VERSION="v0.6.51"
FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="2.10.3-$FLUTTER_CHANNEL"
DART_CHANNEL_PATH="stable/release"
DART_VERSION="2.16.1"
TOOLS_VERSION="v0.1.0.7"
IPFS_VERSION="v0.12.1"

echo "Starting core dependency build..."
apt-get update -y > ./log || ( cat ./log && exit 1 )
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    software-properties-common curl wget git nginx apt-transport-https jq > ./log || ( cat ./log && exit 1 )

echo "INFO: Installing cosign"
if [[ "$(uname -m)" == *"ar"* ]] ; then ARCH="arm64"; else ARCH="amd64" ; fi && echo $ARCH && \
PLATFORM=$(uname) && FILE_NAME=$(echo "cosign-${PLATFORM}-${ARCH}" | tr '[:upper:]' '[:lower:]') && \
 wget https://github.com/sigstore/cosign/releases/download/v1.7.2/$FILE_NAME && chmod +x -v ./$FILE_NAME && \
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

if [ "$(getArch)" == "arm64" ] ; then
    GOLANG_ARCH="arm64"
    DART_ARCH="arm64"
    CDHELPER_ARCH="arm64"
    IPFS_ARCH="arm64"
    GO_EXPECTED_HASH="57a9171682e297df1a5bd287be056ed0280195ad079af90af16dcad4f64710cb"
    DART_EXPECTED_HASH="de9d1c528367f83bbd192bd565af5b7d9d48f76f79baa4c0e4cf64723e3fb8be"
    FLUTTER_EXPECTED_HASH="7e2a28d14d7356a5bbfe516f8a7c9fc0353f85fe69e5cf6af22be2c7c8b45566"
    CDHELPER_EXPECTED_HASH="c2e40c7143f4097c59676f037ac6eaec68761d965bd958889299ab32f1bed6b3"
    IPFS_EXPECTED_HASH="791fdc09d0e3d6f05d0581454b09e8c1d55cef4515170b695ff94075af183edf"
elif [ "$(getArch)" == "amd64" ] ; then
    GOLANG_ARCH="amd64"
    DART_ARCH="x64"
    CDHELPER_ARCH="x64"
    IPFS_ARCH="amd64"
    GO_EXPECTED_HASH="980e65a863377e69fd9b67df9d8395fd8e93858e7a24c9f55803421e453f4f99"
    DART_EXPECTED_HASH="3cc63a0c21500bc5eb9671733843dcc20040b39fdc02f35defcf7af59f88d459"
    FLUTTER_EXPECTED_HASH="7e2a28d14d7356a5bbfe516f8a7c9fc0353f85fe69e5cf6af22be2c7c8b45566"
    CDHELPER_EXPECTED_HASH="082e05210f93036e0008658b6c6bd37ab055bac919865015124a0d72e18a45b7"
    IPFS_EXPECTED_HASH="bd4ab982bf2a50a7e8fc4493bdb0960d7271b27ec1e6d74ef68df404d16b2228"
else
    echoErr "ERROR: Uknown architecture $(getArch)"
    exit 1
fi

echoInfo "INFO: Updating dpeendecies (2)..."
apt-get update -y > ./log || ( cat ./log && exit 1 )

echoInfo "INFO: Installing core dpeendecies..."
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    file build-essential net-tools hashdeep make ca-certificates p7zip-full lsof libglu1-mesa bash gnupg \
    nodejs node-gyp python python3 python3-pip tar unzip xz-utils yarn zip protobuf-compiler golang-goprotobuf-dev \
    golang-grpc-gateway golang-github-grpc-ecosystem-grpc-gateway-dev clang cmake gcc g++ pkg-config libudev-dev \
    libusb-1.0-0-dev curl iputils-ping nano openssl dos2unix > ./log || ( cat ./log && exit 1 )

echoInfo "INFO: Updating dpeendecies (3)..."
apt update -y > ./log || ( cat ./log && exit 1 )
apt install -f -y bc dnsutils psmisc netcat nodejs npm > ./log || ( cat ./log && exit 1 )

echoInfo "INFO: Installing deb package manager..."
echo 'deb [trusted=yes] https://repo.goreleaser.com/apt/ /' | tee /etc/apt/sources.list.d/goreleaser.list && apt-get update -y && \
	apt install nfpm

echoInfo "INFO: Installing python essentials..."
pip3 install crossenv
pip3 install ECPy
pip3 install pyinstaller

echoInfo "INFO: Installing services runner..."
SYSCTRL_DESTINATION=/usr/local/bin/systemctl2
safeWget /usr/local/bin/systemctl2 \
 https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/9cbe1a00eb4bdac6ff05b96ca34ec9ed3d8fc06c/files/docker/systemctl.py \
 "e02e90c6de6cd68062dadcc6a20078c34b19582be0baf93ffa7d41f5ef0a1fdd" > ./log || ( cat ./log && exit 1 )

chmod +x $SYSCTRL_DESTINATION
systemctl2 --version

echoInfo "INFO: Installing binaries..."

GO_TAR="go$GO_VERSION.${OS_VERSION}-$GOLANG_ARCH.tar.gz"
FLUTTER_TAR="flutter_${OS_VERSION}_$FLUTTER_VERSION.tar.xz"
DART_ZIP="dartsdk-${OS_VERSION}-$DART_ARCH-release.zip"
CDHELPER_ZIP="CDHelper-${OS_VERSION}-$CDHELPER_ARCH.zip"

echoInfo "INFO: Installing CDHelper tool"
cd /tmp && safeWget ./$CDHELPER_ZIP "https://github.com/asmodat/CDHelper/releases/download/$CDHELPER_VERSION/$CDHELPER_ZIP" "$CDHELPER_EXPECTED_HASH" > ./log || ( cat ./log && exit 1 )
 
INSTALL_DIR="/usr/local/bin/CDHelper"
rm -rfv $INSTALL_DIR
mkdir -pv $INSTALL_DIR
unzip $CDHELPER_ZIP -d $INSTALL_DIR > ./log || ( cat ./log && exit 1 )
chmod -R 555 $INSTALL_DIR
 
ls -l /bin/CDHelper || echo "INFO: Symlink not found"
rm /bin/CDHelper || echo "INFO: Failed to remove old symlink"
ln -s $INSTALL_DIR/CDHelper /bin/CDHelper || echo "INFO: CDHelper symlink already exists" 
CDHelper version

echoInfo "INFO: Installing latest go $GOLANG_ARCH version $GO_VERSION https://golang.org/doc/install ..."
cd /tmp && safeWget ./$GO_TAR https://dl.google.com/go/$GO_TAR "$GO_EXPECTED_HASH" > ./log || ( cat ./log && exit 1 )
tar -C /usr/local -xf $GO_TAR &>/dev/null
go version

echoInfo "INFO: Installing rust..."
curl https://sh.rustup.rs -sSf | bash -s -- -y
cargo --version

echoInfo "INFO: Setting up essential flutter dependencies..."
cd /tmp && safeWget ./$FLUTTER_TAR https://storage.googleapis.com/flutter_infra_release/releases/$FLUTTER_CHANNEL/${OS_VERSION}/$FLUTTER_TAR "$FLUTTER_EXPECTED_HASH" > ./log || ( cat ./log && exit 1 )

mkdir -p /usr/lib # make sure flutter root directory exists
tar -C /usr/lib -xf ./$FLUTTER_TAR

echoInfo "INFO: Setting up essential dart dependencies..."
FLUTTER_CACHE=$FLUTTERROOT/bin/cache
rm -rf $FLUTTER_CACHE/dart-sdk
mkdir -p $FLUTTER_CACHE # make sure flutter cache direcotry exists & essential files which prevent automatic update
touch $FLUTTER_CACHE/.dartignore
touch $FLUTTER_CACHE/engine-dart-sdk.stamp

echoInfo "INFO: Installing latest dart $DART_ARCH version $DART_VERSION https://dart.dev/get-dart/archive ..."
cd /tmp && safeWget $DART_ZIP https://storage.googleapis.com/dart-archive/channels/$DART_CHANNEL_PATH/$DART_VERSION/sdk/$DART_ZIP "$DART_EXPECTED_HASH" > ./log || ( cat ./log && exit 1 )
unzip ./$DART_ZIP -d $FLUTTER_CACHE > ./log || ( cat ./log && exit 1 )

echoInfo "INFO: Updating dpeendecies (4)..."
apt update -y > ./log || ( cat ./log && exit 1 )
apt install -y android-sdk > ./log || ( cat ./log && exit 1 )

echoInfo "INFO: Installing cmdline-tools"

ANDROID_HOME="/usr/lib/android-sdk"
setGlobEnv ANDROID_HOME "$ANDROID_HOME"
setGlobEnv ANDROID_SDK_ROOT "$ANDROID_HOME"
setGlobPath "${ANDROID_HOME}/tools"
setGlobPath "${ANDROID_HOME}/platform-tools"
loadGlobEnvs

SDKTOOLS_ZIP=./commandlinetools.zip
SDKTOOLS_DIR=$ANDROID_HOME/cmdline-tools/tools
safeWget "$SDKTOOLS_ZIP" "https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip" \
 d71f75333d79c9c6ef5c39d3456c6c58c613de30e6a751ea0dbd433e8f8b9cbf ./log || ( cat ./log && exit 1 )

 rm -rf ./commandlinetools && unzip ./$SDKTOOLS_ZIP -d ./commandlinetools > ./log || ( cat ./log && exit 1 )
 rm -rf $SDKTOOLS_DIR && mkdir -p $SDKTOOLS_DIR
 cp -rf ./commandlinetools/cmdline-tools/* $SDKTOOLS_DIR

setGlobPath $SDKTOOLS_DIR/bin 
loadGlobEnvs
sdkmanager --version

yes | sdkmanager --licenses > ./log || ( cat ./log && exit 1 )
sdkmanager --update > ./log || ( cat ./log && exit 1 )

# NOTE: To find out latest tools versions run 'sdkmanager --list'
sdkmanager --install "platform-tools" "platforms;android-31" "build-tools;30.0.2" "cmdline-tools;6.0" > ./log || ( cat ./log && exit 1 )
yes | sdkmanager --licenses > ./log || ( cat ./log && exit 1 )

echoInfo "INFO: Configuring flutter..."

flutter config --enable-web
flutter doctor
flutter doctor --android-licenses

echoInfo "INFO: Installing FVM..."
dart pub global activate fvm

setGlobPath "$HOME/.pub-cache/bin"
loadGlobEnvs

fvm flutter --version
fvm config --cache-path "$FLUTTER_CACHE"
fvm config

fvm install 2.5.3

echoInfo "INFO: Intstalling IPFS..."
IPFS_TAR="go-ipfs_${IPFS_VERSION}_linux-${IPFS_ARCH}.tar.gz"
cd /tmp && safeWget $IPFS_TAR "https://dist.ipfs.io/go-ipfs/${IPFS_VERSION}/$IPFS_TAR" "$IPFS_EXPECTED_HASH" > ./log || ( cat ./log && exit 1 )

tar -xzf $IPFS_TAR && ./go-ipfs/install.sh
ipfs --version
ipfs init

echoInfo "INFO: Updating dpeendecies (4)..."
# CHROME_EXECUTABLE=""
# apt purge -y google-chrome  > ./log || echoWarn "WARNING: Failed to remove old goole-chrome or the app did not exist"
# apt purge -y chromium  > ./log || echoWarn "WARNING: Failed to remove old chromium or the app did not exist"
# apt purge -y chromium-browser  > ./log || echoWarn "WARNING: Failed to remove old chromium-browser or the app did not exist"
# rm -rfv /var/cache/apt/archives/chromium* /usr/bin/chromedriver
# apt --fix-broken install -y > ./log || ( cat ./log && exit 1 )

# ref.: http://ftp.debian.org/debian/pool/main/c/chromium/
apt update -y > ./log || ( cat ./log && exit 1 )
apt install -y gdebi-core libnss3 libgconf-2-4 libappindicator1 fonts-liberation xvfb libxi6 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi-dev \
  libxtst-dev libnss3 libcups2 libxss1 libxrandr2 libasound2 libatk1.0-0 libatk-bridge2.0-0 libpangocairo-1.0-0 libgtk-3-0 libgbm1 > ./log || ( cat ./log && exit 1 )

# add-apt-repository -y ppa:system76/pop
# apt install -f -y chromium > ./log || ( echoWarn "WARNING: chromium might NOT be available on $(getArch)" && cat ./log )
# add-apt-repository -y ppa:saiarcot895/chromium-dev > ./log || ( cat ./log && exit 1 )
# apt update -y > ./log || ( cat ./log && exit 1 )
# apt install -f -y chromium-browser || ( echoWarn "WARNING: chromium-browser might NOT be available on $(getArch)" && cat ./log )

# if [ "$(getArch)" == "amd64" ] ; then
#     GOOLGE_CHROME_FILE="google-chrome-stable_current_amd64.deb"
#     wget https://dl.google.com/linux/direct/$GOOLGE_CHROME_FILE
#     gdebi -n ./$GOOLGE_CHROME_FILE
# 
#     CHROME_DRIVER_FILE="chromedriver_linux64.zip"
#     wget https://chromedriver.storage.googleapis.com/100.0.4896.20/$CHROME_DRIVER_FILE
#     unzip $CHROME_DRIVER_FILE
#     mv -fv chromedriver /usr/bin/chromedriver
#     chmod +x /usr/bin/chromedriver
#     chromedriver --version
#     CHROMEDRIVER_EXECUTABLE=$(which chromedriver || echo "")
# 
#     cat > /etc/systemd/system/chromedriver.service << EOL
# [Unit]
# Description=Local Chrome Integration Test Service
# After=network.target
# [Service]
# MemorySwapMax=0
# Type=simple
# User=root
# WorkingDirectory=/root
# ExecStart=$CHROMEDRIVER_EXECUTABLE --port=4444
# Restart=always
# RestartSec=5
# LimitNOFILE=4096
# [Install]
# WantedBy=default.target
# EOL
# 
# fi

# CHROME_VERSION=$(google-chrome --version 2> /dev/null || echo "")
# if (! $(isNullOrWhitespaces "$CHROME_VERSION"))  ; then
#     CHROME_VERSION=$(google-chrome --version || echo "")
#     CHROME_EXECUTABLE=$(which google-chrome || echo "")
# else
#     CHROME_VERSION=$(chromium --version 2> /dev/null || echo "")
#     if (! $(isNullOrWhitespaces "$CHROME_VERSION"))  ; then
#         CHROME_VERSION=$(chromium --version || echo "")
#         CHROME_EXECUTABLE=$(which chromium || echo "")
#     else
#         CHROME_VERSION=$(chromium-browser --version 2> /dev/null || echo "")
#         CHROME_EXECUTABLE=$(which chromium-browser || echo "")
#     fi
# fi
# 
# if [ -z "$CHROME_EXECUTABLE" ] || ($(isNullOrWhitespaces "$CHROME_VERSION"))  ; then
#     echoErr "ERROR: Failed to find chrome executable"
#     exit 1
# else
#     $CHROME_EXECUTABLE --version
# fi

echoInfo "INFO: Cleanup..."
rm -fv $DART_ZIP $FLUTTER_TAR $IPFS_TAR