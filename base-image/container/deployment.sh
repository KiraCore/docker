#!/usr/bin/env bash
exec 2>&1
set -e
set -x

# define versions of the software to install manually
ARCHITECTURE=$(uname -m)
OS_VERSION=$(uname) && OS_VERSION="${OS_VERSION,,}"
GO_VERSION="1.18.3"
CDHELPER_VERSION="v0.6.51"
FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="2.10.3-$FLUTTER_CHANNEL"
DART_CHANNEL_PATH="stable/release"
DART_VERSION="2.16.1"
TOOLS_VERSION="v0.2.2"
IPFS_VERSION="v0.12.1"

echo "Starting core dependency build..."
apt-get update -y > ./log || ( cat ./log && exit 1 )
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    software-properties-common curl wget git nginx apt-transport-https jq sudo > ./log || ( cat ./log && exit 1 )

add-apt-repository -y ppa:deadsnakes/ppa
add-apt-repository -y ppa:mozillateam/firefox-next

echo "Creating kira user..."
USERNAME=kira
useradd -s /bin/bash -d $KIRA_HOME -m -G sudo $USERNAME
usermod -aG sudo $USERNAME

echo "Removing file I/O limits..."
echo "* hard nofile 131072" >> /etc/security/limits.conf
echo "* soft nofile 131072" >> /etc/security/limits.conf
echo "* hard nproc 131072" >> /etc/security/limits.conf
echo "* soft nproc 131072" >> /etc/security/limits.conf
echo "root hard nofile 131072" >> /etc/security/limits.conf
echo "root soft nofile 131072" >> /etc/security/limits.conf
echo "session required pam_limits.so" >> /etc/security/limits.conf
echo "DefaultLimitNOFILE=131072" >> /etc/systemd/system.conf
echo "DefaultLimitNOFILE=131072" >> /etc/systemd/user.conf
# NOTE: For some reason this file is read only
# echo 1024 > /proc/sys/fs/inotify/max_user_instances
echo "fs.file-max = 131072" >> /etc/sysctl.conf
echo "fs.inotify.max_user_instances = 1024" >> /etc/sysctl.conf
ulimit -n

echo "INFO: Installing cosign"
if [[ "$(uname -m)" == *"ar"* ]] ; then ARCH="arm64"; else ARCH="amd64" ; fi && echo $ARCH && \
PLATFORM=$(uname) && FILE_NAME=$(echo "cosign-${PLATFORM}-${ARCH}" | tr '[:upper:]' '[:lower:]') && \
 wget https://github.com/sigstore/cosign/releases/download/v1.7.2/$FILE_NAME && chmod +x -v ./$FILE_NAME && \
 mv -fv ./$FILE_NAME /usr/local/bin/cosign

cosign version

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

# go checksums: https://go.dev/dl/
if [ "$(getArch)" == "arm64" ] ; then
    DART_ARCH="arm64"
    CDHELPER_ARCH="arm64"
elif [ "$(getArch)" == "amd64" ] ; then
    DART_ARCH="x64"
    CDHELPER_ARCH="x64"
else
    echoErr "ERROR: Uknown architecture $(getArch)"
    exit 1
fi

echoInfo "INFO: Updating dpeendecies (2)..."
apt-get update -y > ./log || ( cat ./log && exit 1 )

echoInfo "INFO: Installing core dpeendecies..."
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    file build-essential net-tools hashdeep make ca-certificates p7zip-full lsof libglu1-mesa bash gnupg \
    nodejs node-gyp python python3.10 python3.10-distutils python3.10-dev python3.10-venv tar unzip xz-utils \
    yarn zip protobuf-compiler golang-goprotobuf-dev golang-grpc-gateway golang-github-grpc-ecosystem-grpc-gateway-dev \
    clang cmake gcc g++ pkg-config libudev-dev libusb-1.0-0-dev curl iputils-ping nano openssl dos2unix dbus > ./log || ( cat ./log && exit 1 )

# NOTE: python3-pip is not compatible, use boottrap instead:
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10
python3.10 -m pip install --upgrade pip setuptools wheel

git clone https://github.com/pyinstaller/pyinstaller.git -b v4.10
cd ./pyinstaller/bootloader && python3.10 ./waf all
cd .. && python3.10 setup.py install
cd ..

pyinstaller --version

#pip3 install pyinstaller
pip3 install crossenv
pip3 install ECPy

echoInfo "INFO: Updating dpeendecies (3)..."
apt update -y > ./log || ( cat ./log && exit 1 )
apt install -f -y bc dnsutils psmisc netcat nodejs npm > ./log || ( cat ./log && exit 1 )

echoInfo "INFO: Installing deb package manager..."
echo 'deb [trusted=yes] https://repo.goreleaser.com/apt/ /' | tee /etc/apt/sources.list.d/goreleaser.list && apt-get update -y && \
	apt install nfpm

echoInfo "INFO: Installing services runner..."
SYSCTRL_DESTINATION=/usr/bin/systemctl
safeWget $SYSCTRL_DESTINATION \
 https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/9cbe1a00eb4bdac6ff05b96ca34ec9ed3d8fc06c/files/docker/systemctl.py \
 "e02e90c6de6cd68062dadcc6a20078c34b19582be0baf93ffa7d41f5ef0a1fdd" > ./log || ( cat ./log && exit 1 )

chmod 755 $SYSCTRL_DESTINATION
systemctl --version

echoInfo "INFO: Installing binaries..."

GO_TAR="go$GO_VERSION.${OS_VERSION}-$(getArch).tar.gz"
FLUTTER_TAR="flutter_${OS_VERSION}_$FLUTTER_VERSION.tar.xz"
DART_ZIP="dartsdk-${OS_VERSION}-$DART_ARCH-release.zip"
CDHELPER_ZIP="CDHelper-${OS_VERSION}-$CDHELPER_ARCH.zip"

echoInfo "INFO: Installing CDHelper tool"
cd /tmp && safeWget ./$CDHELPER_ZIP "https://github.com/asmodat/CDHelper/releases/download/$CDHELPER_VERSION/$CDHELPER_ZIP" \
 "082e05210f93036e0008658b6c6bd37ab055bac919865015124a0d72e18a45b7,c2e40c7143f4097c59676f037ac6eaec68761d965bd958889299ab32f1bed6b3" > ./log || ( cat ./log && exit 1 )
 
INSTALL_DIR="/usr/local/bin/CDHelper"
rm -rfv $INSTALL_DIR
mkdir -pv $INSTALL_DIR
unzip $CDHELPER_ZIP -d $INSTALL_DIR > ./log || ( cat ./log && exit 1 )
chmod -R 555 $INSTALL_DIR
 
ls -l /bin/CDHelper || echo "INFO: Symlink not found"
rm /bin/CDHelper || echo "INFO: Failed to remove old symlink"
ln -s $INSTALL_DIR/CDHelper /bin/CDHelper || echo "INFO: CDHelper symlink already exists" 
CDHelper version

echoInfo "INFO: Installing latest go version $GO_VERSION https://golang.org/doc/install ..."
cd /tmp && safeWget ./$GO_TAR https://dl.google.com/go/$GO_TAR \
 "fc4ad28d0501eaa9c9d6190de3888c9d44d8b5fb02183ce4ae93713f67b8a35b,e54bec97a1a5d230fc2f9ad0880fcbabb5888f30ed9666eca4a91c5a32e86cbc" && \
 tar -C /usr/local -xf $GO_TAR &>/dev/null && go version

echoInfo "INFO: Installing rust..."
curl https://sh.rustup.rs -sSf | bash -s -- -y
cargo --version

echoInfo "INFO: Setting up essential flutter dependencies..."
cd /tmp && safeWget ./$FLUTTER_TAR https://storage.googleapis.com/flutter_infra_release/releases/$FLUTTER_CHANNEL/${OS_VERSION}/$FLUTTER_TAR \
 "7e2a28d14d7356a5bbfe516f8a7c9fc0353f85fe69e5cf6af22be2c7c8b45566" > ./log || ( cat ./log && exit 1 )

mkdir -p /usr/lib # make sure flutter root directory exists
tar -C /usr/lib -xf ./$FLUTTER_TAR

echoInfo "INFO: Setting up essential dart dependencies..."
FLUTTER_CACHE=$FLUTTERROOT/bin/cache
rm -rf $FLUTTER_CACHE/dart-sdk
mkdir -p $FLUTTER_CACHE # make sure flutter cache direcotry exists & essential files which prevent automatic update
touch $FLUTTER_CACHE/.dartignore
touch $FLUTTER_CACHE/engine-dart-sdk.stamp

echoInfo "INFO: Installing latest dart $DART_ARCH version $DART_VERSION https://dart.dev/get-dart/archive ..."
cd /tmp && safeWget $DART_ZIP https://storage.googleapis.com/dart-archive/channels/$DART_CHANNEL_PATH/$DART_VERSION/sdk/$DART_ZIP \
 "3cc63a0c21500bc5eb9671733843dcc20040b39fdc02f35defcf7af59f88d459,de9d1c528367f83bbd192bd565af5b7d9d48f76f79baa4c0e4cf64723e3fb8be" > ./log || ( cat ./log && exit 1 )
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
 "d71f75333d79c9c6ef5c39d3456c6c58c613de30e6a751ea0dbd433e8f8b9cbf" ./log || ( cat ./log && exit 1 )

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

# git exception for the flutter directotry is require
git config --global --add safe.directory /usr/lib/flutter

echoInfo "INFO: Intstalling IPFS tools..."
cd /tmp

IPFS_TAR="go-ipfs_${IPFS_VERSION}_linux-$(getArch).tar.gz"

safeWget "$IPFS_TAR" "https://dist.ipfs.io/go-ipfs/${IPFS_VERSION}/$IPFS_TAR" \
 "bd4ab982bf2a50a7e8fc4493bdb0960d7271b27ec1e6d74ef68df404d16b2228,791fdc09d0e3d6f05d0581454b09e8c1d55cef4515170b695ff94075af183edf" > ./log || ( cat ./log && exit 1 )

tar -xzf "$IPFS_TAR" && ./go-ipfs/install.sh
ipfs --version
ipfs init

BIN_DEST="/usr/local/bin/ipfs-api"
IPFS_DEB="/tmp/ipfs-api.deb"

safeWget "$IPFS_DEB" "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/ipfs-api-linux-$(getArch).deb" "$KIRA_COSIGN_PUB" && \
  dpkg-deb -x "$IPFS_DEB" ./ipfs-api && cp -fv "/tmp/ipfs-api/bin/ipfs-api" $BIN_DEST && chmod -v 755 $BIN_DEST

ipfs-api version

echoInfo "INFO: Updating dpeendecies (4)..."
# CHROME_EXECUTABLE=""
# apt purge -y google-chrome  > ./log || echoWarn "WARNING: Failed to remove old goole-chrome or the app did not exist"
# apt purge -y chromium  > ./log || echoWarn "WARNING: Failed to remove old chromium or the app did not exist"
# apt purge -y chromium-browser  > ./log || echoWarn "WARNING: Failed to remove old chromium-browser or the app did not exist"
# rm -rfv /var/cache/apt/archives/chromium* /usr/bin/chromedriver
# apt --fix-broken install -y > ./log || ( cat ./log && exit 1 )

# ref.: http://ftp.debian.org/debian/pool/main/c/chromium/
apt update -y > ./log || ( cat ./log && exit 1 )
apt install -y gconf-service gdebi-core libgconf-2-4 libappindicator1 fonts-liberation xvfb libxi6 libx11-xcb1 libxcomposite1 libxcursor1 lsb-release \
 libxdamage1 libxi-dev libxtst-dev libnss3 libcups2 libxss1 libxrandr2 libasound2 libatk1.0-0 libatk-bridge2.0-0 libpangocairo-1.0-0 libgtk-3-0 \
 libgbm1 libc6 libcairo2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgdk-pixbuf2.0-0 libglib2.0-0 libnspr4 libpango-1.0-0 libstdc++6 libx11-6 \
 libxcb1 libxext6 libxfixes3 libxrender1 libxtst6 xdg-utils libgbm-dev x11-apps > ./log || ( cat ./log && exit 1 )

echoInfo "INFO: Installing firefox..."
# Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &
apt-get update -y > ./log || ( cat ./log && exit 1 )
apt-get install -y firefox firefox-geckodriver libpci3 libegl-dev
# xvfb-run firefox http://google.com
# xvfb-run chromedriver --version
# xvfb-run -e /dev/stdout firefox https://google.com

if [ "$(getArch)" == "amd64" ] ; then
    # Installing google-chrome Dart Debug extension, ref.: https://chrome.google.com/webstore/detail/dart-debug-extension/?hl=en
    # See chrome CRX Extraction/Downloader extension to generte zip file
    wget https://ipfs.kira.network/ipfs/QmQBjogqwQwAkURAQotvLFCcLwys19JAAu9yFqhSF7hBtY -O ./dart-debug.zip
    EXTENSIONS_DIR=/opt/google/chrome/extensions
    EXTENSIONS_PATH="${EXTENSIONS_DIR}/eljbmlghnomdjgdjmbdekegdkbabckhm/1.28_0"
    mkdir -p $EXTENSIONS_PATH && unzip ./dart-debug.zip -d $EXTENSIONS_PATH && chmod -v 777 $EXTENSIONS_DIR

    EXTENSIONS_DIR=/root/.config/google-chrome/Default/Extensions
    EXTENSIONS_PATH="${EXTENSIONS_DIR}/eljbmlghnomdjgdjmbdekegdkbabckhm/1.28_0"
    mkdir -p $EXTENSIONS_PATH && unzip ./dart-debug.zip -d $EXTENSIONS_PATH && chmod -v 777 $EXTENSIONS_DIR

    EXTENSIONS_DIR=$KIRA_HOME/.config/google-chrome/Default/Extensions
    EXTENSIONS_PATH="${EXTENSIONS_DIR}/eljbmlghnomdjgdjmbdekegdkbabckhm/1.28_0"
    mkdir -p $EXTENSIONS_PATH && unzip ./dart-debug.zip -d $EXTENSIONS_PATH && chmod -v 777 $EXTENSIONS_DIR

    install_chrome_extension () {
      default_dir=$(dirname $1)
      mkdir -p $1 $default_dir/policies/managed $default_dir/policies/recommended
      pref_file_path="$1/$2.json"
      policy_file_path="$default_dir/policies/managed/test_policy.json"
      upd_url="https://clients2.google.com/service/update2/crx"
      echo "{" > "$pref_file_path"
      echo "  \"external_update_url\": \"$upd_url\"" >> "$pref_file_path"
      echo "}" >> "$pref_file_path"
      echo "{" > "$policy_file_path"
      echo "  \"ExtensionInstallForcelist\": [\"$2,$upd_url\""] >> "$policy_file_path"
      echo "}" >> "$policy_file_path"
      chmod -Rv 777 $default_dir
      echoInfo "Added \"$pref_file_path\" -> $3"
    }

    install_chrome_extension /opt/google/chrome/extensions "eljbmlghnomdjgdjmbdekegdkbabckhm" "Dart Debug Extension"
    install_chrome_extension /root/.config/google-chrome/Default/Extensions "eljbmlghnomdjgdjmbdekegdkbabckhm" "Dart Debug Extension"
    install_chrome_extension $KIRA_HOME/.config/google-chrome/Default/Extensions "eljbmlghnomdjgdjmbdekegdkbabckhm" "Dart Debug Extension"

    GOOLGE_CHROME_FILE="google-chrome-stable_current_amd64.deb"
    wget https://dl.google.com/linux/direct/$GOOLGE_CHROME_FILE
    gdebi -n ./$GOOLGE_CHROME_FILE
    google-chrome --version
    # create chrome working directory
    CHROME_WORK_DIR=$KIRA_HOME/.local
    mkdir -p $CHROME_WORK_DIR && chmod -R 777 $CHROME_WORK_DIR

    CHROME_DRIVER_FILE="chromedriver_linux64.zip"
    wget https://chromedriver.storage.googleapis.com/100.0.4896.20/$CHROME_DRIVER_FILE
    unzip $CHROME_DRIVER_FILE
    mv -fv chromedriver /usr/bin/chromedriver
    chmod +x /usr/bin/chromedriver
    chromedriver --version
    CHROMEDRIVER_EXECUTABLE=$(which chromedriver)
    XVFB_FILE=$(which xvfb-run)

    cat > /etc/systemd/system/chromedriver.service << EOL
[Unit]
Description=Local Chrome Integration Test Service
After=network.target
[Service]
MemorySwapMax=0
Type=simple
User=$USERNAME
WorkingDirectory=$KIRA_HOME
ExecStart=$XVFB_FILE $CHROMEDRIVER_EXECUTABLE --port=4444 --verbose 
Restart=always
RestartSec=5
LimitNOFILE=4096
[Install]
WantedBy=default.target
EOL

    systemctl daemon-reload
    systemctl enable chromedriver
    # systemctl stop chromedriver
    # systemctl restart chromedriver
    # systemctl -l --no-pager status chromedriver

    # Additionally run dbus
    # service dbus start
    # service dbus stop    
fi

echoInfo "INFO: Cleanup..."
rm -fv $DART_ZIP $FLUTTER_TAR $IPFS_TAR $IPFS_DEB $SDKTOOLS_ZIP $GO_TAR $CDHELPER_ZIP ./dart-debug.zip
rm -rfv /tmp/ipfs-api