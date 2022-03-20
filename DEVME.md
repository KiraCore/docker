# docker
KIRA Docker Images

# Workflows

In order to have ability to modify & push workflows to github from the local machines
*  Generate a "Personal Access Token" with workflow rights
*  Change Remote url to https://YOUR_USERNAME:YOUR_TOKEN@github.com/KiraCore/docker.git

# Signatures

All containers are signed with [cosign](https://github.com/sigstore/cosign/releases)

Cosign requires simple initial setup of the signer keys described more precisely [here](https://dev.to/n3wt0n/sign-your-container-images-with-cosign-github-actions-and-github-container-registry-3mni)


## Cosign

```
# create keys & add to Actions secrets in org settings
# COSIGN_PASSWORD
# COSIGN_PRIVATE_KEY
# COSIGN_PUBLIC_KEY
cosign generate-key-pair

```


# Build

```
# set env variable to your local repos (will vary depending on the user)
setGlobEnv DOCKER_REPO "/mnt/c/Users/asmodat/Desktop/KIRA/KIRA-CORE/GITHUB/docker"

cd $DOCKER_REPO

make build
```