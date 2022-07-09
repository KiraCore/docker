# base-image

The default image used for building & installing essential tools

## Check FLutter Hash
```
# Flutter is architecture neutral
# Latest FLutter & Dart releases info: https://docs.flutter.dev/development/tools/sdk/releases?tab=linux
OS_VERSION=linux && \
 FLUTTER_CHANNEL="stable" && \
 FLUTTER_VERSION="3.0.4-$FLUTTER_CHANNEL" \
 FLUTTER_TAR="flutter_${OS_VERSION,,}_$FLUTTER_VERSION.tar.xz" && cd /tmp && rm -fv $FLUTTER_TAR && \
 wget https://storage.googleapis.com/flutter_infra_release/releases/$FLUTTER_CHANNEL/${OS_VERSION,,}/$FLUTTER_TAR && \
 echo $(sha256sum ./$FLUTTER_TAR | awk '{ print $1 }')
```

## Check Dart Hash
```
OS_VERSION=linux && \
 DART_CHANNEL_PATH="stable/release"
 DART_VERSION="2.17.5" && \
 DART_ZIP_X64="dartsdk-${OS_VERSION,,}-x64-release.zip" && \
 DART_ZIP_ARM64="dartsdk-${OS_VERSION,,}-arm64-release.zip" && \
 wget https://storage.googleapis.com/dart-archive/channels/$DART_CHANNEL_PATH/$DART_VERSION/sdk/$DART_ZIP_X64 && \
 wget https://storage.googleapis.com/dart-archive/channels/$DART_CHANNEL_PATH/$DART_VERSION/sdk/$DART_ZIP_ARM64 && \
 echo "  Release x64: $(sha256sum ./$DART_ZIP_X64 | awk '{ print $1 }')" && \
 echo "Release arm64: $(sha256sum ./$DART_ZIP_ARM64 | awk '{ print $1 }')"
```

## Check Go Version
```
OS_VERSION=linux && \
 GO_VERSION="1.17.8" && \
 GO_TAR_X64="go$GO_VERSION.${OS_VERSION}-amd64.tar.gz" && \
 GO_TAR_ARM64="go$GO_VERSION.${OS_VERSION}-arm64.tar.gz" && \
 wget https://dl.google.com/go/$GO_TAR_X64 && \
 wget https://dl.google.com/go/$GO_TAR_ARM64 && \
 echo "  Release x64: $(sha256sum ./$GO_TAR_X64 | awk '{ print $1 }')" && \
 echo "Release arm64: $(sha256sum ./$GO_TAR_ARM64 | awk '{ print $1 }')"
```

## Check IPFS Version
```
OS_VERSION=linux && \
 IPFS_VERSION="v0.12.1" && \
 IPFS_TAR_X64="go-ipfs_${IPFS_VERSION}_${OS_VERSION}-amd64.tar.gz" && \
 IPFS_TAR_ARM64="go-ipfs_${IPFS_VERSION}_${OS_VERSION}-arm64.tar.gz" && \
 wget https://dist.ipfs.io/go-ipfs/${IPFS_VERSION}/$IPFS_TAR_X64 && \
 wget https://dist.ipfs.io/go-ipfs/${IPFS_VERSION}/$IPFS_TAR_ARM64 && \
 echo "  Release x64: $(sha256sum ./$IPFS_TAR_X64 | awk '{ print $1 }')" && \
 echo "Release arm64: $(sha256sum ./$IPFS_TAR_ARM64 | awk '{ print $1 }')"
```

## Check COSIGN Version
```
OS_VERSION=linux && \
 VERSION="v1.7.2" && \
 FILE_X64="cosign-${OS_VERSION}-amd64" && \
 FILE_ARM64="cosign-${OS_VERSION}-arm64" && \
 wget https://github.com/sigstore/cosign/releases/download/${VERSION}/$FILE_X64 && \
 wget https://github.com/sigstore/cosign/releases/download/${VERSION}/$FILE_ARM64 && \
 echo "  Release x64: $(sha256sum ./$FILE_X64 | awk '{ print $1 }')" && \
 echo "Release arm64: $(sha256sum ./$FILE_ARM64 | awk '{ print $1 }')"
```

## Run Container Locally
```
docker pull ghcr.io/kiracore/docker/base-image:v0.10.7
docker run -i -t ghcr.io/kiracore/docker/base-image:v0.10.7 /bin/bash
```

