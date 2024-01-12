# docker
KIRA Docker Images

# Signatures
All containers are signed with [cosign](https://github.com/sigstore/cosign/releases)

## Cosign Install (linux)

```
# install cosign
CS_VERSION="2.0.2" && ARCH=$(([[ "$(uname -m)" == *"arm"* ]] || [[ "$(uname -m)" == *"aarch"* ]]) && echo "arm64" || echo "amd64") && \
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
cosign verify --key ./cosign.pub ghcr.io/kiracore/docker/base-image:v0.13.14
```

## Launch Container Locally
```
# To launch test container run
BASE_NAME="test" && \
 BASE_IMG="ghcr.io/kiracore/docker/kira-base:v0.13.15" && \
 docker run -i -t -d --privileged --net bridge --name $BASE_NAME --hostname test.local $BASE_IMG /bin/bash

# Note: If you want to run an extra container inside the KIRA Manager, replace '--net bridge' flag with '--net kiranet'

# Find container ID by Name
id=$(timeout 3 docker ps --no-trunc -aqf "name=^${BASE_NAME}$" 2> /dev/null || echo -n "") && echo $id

# To start existing container
# one liner: docker start -i $(timeout 3 docker ps --no-trunc -aqf "name=^${BASE_NAME}$" 2> /dev/null || echo -n "")
docker start -i $id

# Delete specific container
# one liner: docker rm -f $(timeout 3 docker ps --no-trunc -aqf "name=^${BASE_NAME}$" 2> /dev/null || echo -n "")
docker rm -f $id
```
