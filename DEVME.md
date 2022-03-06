# docker
KIRA Docker Images

# Signatures

All containers are signed with [cosign](https://github.com/sigstore/cosign/releases)

Cosign requires simple initial setup of the signer keys described more precisely [here](https://dev.to/n3wt0n/sign-your-container-images-with-cosign-github-actions-and-github-container-registry-3mni)


## Cosign

```
# install cosign
CS_VERSION="1.6.0" && ARCH=$(([[ "$(uname -m)" == *"arm"* ]] || [[ "$(uname -m)" == *"aarch"* ]]) && echo "arm64" || echo "amd64") && \
    OS_VERSION=$(uname) && CS_DEB="cosign_${CS_VERSION}_${ARCH}.deb" && cd /tmp && rm -fv ./$CS_DEB && \
    (dpkg -r cosign || ( echo "WARNING: Failed to remove old cosign version" && sleep 1 ) ) && \
    wget https://github.com/sigstore/cosign/releases/download/v${CS_VERSION}/${CS_DEB} && \
    chmod -R 777 "$CS_DEB" && dpkg -i $CS_DEB && CS_EXE="cosign-${OS_VERSION,,}-$ARCH" && \
    ln -sf /usr/local/bin/$CS_EXE /usr/local/bin/cosign && cosign version

# create keys & add to Actions secrets in org settings
# COSIGN_PASSWORD
# COSIGN_PRIVATE_KEY
# COSIGN_PUBLIC_KEY
cosign generate-key-pair


```
