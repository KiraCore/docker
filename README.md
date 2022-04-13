# docker
KIRA Docker Images

# Signatures
All containers are signed with [cosign](https://github.com/sigstore/cosign/releases)

## Cosign Install (linux)

```
# install cosign
CS_VERSION="1.6.0" && ARCH=$(([[ "$(uname -m)" == *"arm"* ]] || [[ "$(uname -m)" == *"aarch"* ]]) && echo "arm64" || echo "amd64") && \
    OS_VERSION=$(uname) && CS_DEB="cosign_${CS_VERSION}_${ARCH}.deb" && cd /tmp && rm -fv ./$CS_DEB && \
    (dpkg -r cosign || ( echo "WARNING: Failed to remove old cosign version" && sleep 1 ) ) && \
    wget https://github.com/sigstore/cosign/releases/download/v${CS_VERSION}/${CS_DEB} && \
    chmod -R 777 "$CS_DEB" && dpkg -i $CS_DEB && CS_EXE="cosign-${OS_VERSION,,}-$ARCH" && \
    ln -sf /usr/local/bin/$CS_EXE /usr/local/bin/cosign && cosign version
```

## Cosign Public Key
```
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE/IrzBQYeMwvKa44/DF/HB7XDpnE+
f+mU9F/Qbfq25bBWV2+NlYMJv3KvKHNtu3Jknt6yizZjUV4b8WGfKBzFYw==
-----END PUBLIC KEY-----
```

## Cosign Verification Example
```
cosign verify --key ./cosign.pub ghcr.io/kiracore/docker/base-image:v0.9.0.0
```

