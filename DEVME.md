# docker
KIRA Docker Images

# Workflows

In order to have ability to modify & push workflows to github from the local machines
*  Generate a "Personal Access Token" with workflow rights
*  Change Remote url to https://YOUR_USERNAME:YOUR_TOKEN@github.com/KiraCore/docker.git

Not all actions can be run on AMD64, a runner called `github-actions-arm64-runner-1` run under `su - asmodat`. This machine is essential to enable build of ARM64 binaries (e.g. using pyinstall). The runner requires its job to run perpetually thus a dedicated systemd service must be in place:

To add new runners use: `https://github.com/organizations/KiraCore/settings/actions/runners/new?arch=arm64&os=linux`

```bash
# install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-get -y update && dpkg --configure -a
apt install -y bridge-utils containerd docker.io 
systemctl enable --now docker && docker -v

# create user
sudo adduser asmodat
# add user to desired groups (do NOT use sudo, this is just example)
sudo adduser asmodat sudo
su - asmodat

# add user to docker group
sudo usermod -aG docker asmodat
sudo chown root:docker /var/run/docker.sock

# run commands as per: https://github.com/organizations/KiraCore/settings/actions/runners/new?arch=arm64&os=linux
# Name: github-actions-<arch>-runner-<id>
# Tag: <arch>
exit

sudo -s
cat > /etc/systemd/system/actions.service << EOL
[Unit]
Description=Actions Runner
After=network.target
[Service]
MemorySwapMax=0
Type=simple
User=asmodat
WorkingDirectory=/home/asmodat/actions-runner
ExecStart=/usr/bin/bash /home/asmodat/actions-runner/run.sh
Restart=always
RestartSec=5
LimitNOFILE=4096
[Install]
WantedBy=default.target
EOL

systemctl enable actions 
systemctl start actions
systemctl status actions

systemctl restart docker && sleep 3 && systemctl status docker
systemctl restart actions && sleep 3 && systemctl status actions
```

# Signatures

All containers are signed with [cosign](https://github.com/sigstore/cosign/releases)

Cosign requires simple initial setup of the signer keys described more precisely [here](https://dev.to/n3wt0n/sign-your-container-images-with-cosign-github-actions-and-github-container-registry-3mni)


## Cosign

```bash
# create keys & add to Actions secrets in org settings
# COSIGN_PASSWORD
# COSIGN_PRIVATE_KEY
# COSIGN_PUBLIC_KEY
cosign generate-key-pair

# signing & verifying data blobs
export COSIGN_PASSWORD="pass"
cosign sign-blob --key=./cosign.key --output=./nim.sig ./nim
cosign verify-blob --key=./cosign.pub --signature=./nim.sig ./nim
```


# Build

```bash
# set env variable to your local repos (will vary depending on the user)
setGlobEnv DOCKER_REPO "/mnt/c/Users/asmodat/Desktop/KIRA/KIRA-CORE/GITHUB/docker"

cd $DOCKER_REPO

make build
```