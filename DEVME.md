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

# To remove existing runner
cd /home/asmodat/actions-runner
./config.sh remove
```

Workflows runners cleanup

```
docker rm -vf $(docker ps -aq) || echo "WARNING: Failed to remove containers"
docker rmi -f $(docker images -aq) || echo "WARNING: Failed to remove images"
docker system prune -a -f  || echo "WARNING: Failed to prune data"
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

# Chromedriver for workflow runners

Chromedriver installation on Linux

```
apt update -y && \
apt install -y gconf-service gdebi-core libgconf-2-4 libappindicator1 fonts-liberation xvfb libxi6 libx11-xcb1 libxcomposite1 libxcursor1 lsb-release \
 libxdamage1 libxi-dev libxtst-dev libnss3 libcups2 libxss1 libxrandr2 libasound2 libatk1.0-0 libatk-bridge2.0-0 libpangocairo-1.0-0 libgtk-3-0 \
 libgbm1 libc6 libcairo2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgdk-pixbuf2.0-0 libglib2.0-0 libnspr4 libpango-1.0-0 libstdc++6 libx11-6 \
 libxcb1 libxext6 libxfixes3 libxrender1 libxtst6 xdg-utils libgbm-dev x11-apps unzip jq netcat inetutils-inetd

# Install on AMD (ensure that chrome & chromedriver versions match exactly)
CHROME_DRIVER_FILE="chromedriver_linux64.zip" && rm -fv $CHROME_DRIVER_FILE && \
    wget https://chromedriver.storage.googleapis.com/103.0.5060.53/$CHROME_DRIVER_FILE && \
    unzip $CHROME_DRIVER_FILE && \
    mv -fv chromedriver /usr/bin/chromedriver && \
    chmod +x /usr/bin/chromedriver && \
    chromedriver --version

# Install on ARM
CHROME_DRIVER_FILE="chromedriver-v20.0.0-beta.4-linux-arm64.zip" && \
    wget https://github.com/electron/electron/releases/download/v20.0.0-beta.4/$CHROME_DRIVER_FILE && \
    unzip $CHROME_DRIVER_FILE && \
    mv -fv chromedriver /usr/bin/chromedriver && \
    chmod +x /usr/bin/chromedriver && \
    chromedriver --version

CHROMEDRIVER_EXECUTABLE=$(which chromedriver) && \
    mkdir -p /home/asmodat/.chromedriver && \
    XVFB_FILE=$(which xvfb-run) && \
    cat > /etc/systemd/system/chromedriver.service << EOL
[Unit]
Description=Local Chrome Integration Test Service
After=network.target
[Service]
MemorySwapMax=0
Type=simple
User=asmodat
WorkingDirectory=/home/asmodat/.chromedriver
ExecStart=$XVFB_FILE $CHROMEDRIVER_EXECUTABLE --port=4444 --verbose --whitelisted-ips=""
Restart=always
RestartSec=5
LimitNOFILE=4096
[Install]
WantedBy=default.target
EOL

systemctl daemon-reload && \
    systemctl enable chromedriver && \
    systemctl restart chromedriver && \
    systemctl status chromedriver
```

Chromedriver Installation on windows

```
mkdir -p /d/cli/chromedriver && cd /d/cli/chromedriver
wget https://github.com/electron/electron/releases/download/v20.0.0-beta.4/chromedriver-v20.0.0-beta.4-win32-x64.zip

# unzip

# open bash shell & run
/d/cli/chromedriver/chromedriver.exe --port=4444 --verbose --whitelisted-ips=""

# open powershell (As administrator)
New-NetFirewallRule -DisplayName "WSL" -Direction Inbound  -InterfaceAlias "vEthernet (WSL)"  -Action Allow
New-NetFireWallRule -DisplayName 'WSL firewall unlock' -Direction Outbound -LocalPort 4444 -Action Allow -Protocol TCP
New-NetFireWallRule -DisplayName 'WSL firewall unlock' -Direction Inbound -LocalPort 4444 -Action Allow -Protocol TCP

# Launch Windows Defender Firewall -> Advanced Security
# On the left pane select Outbound Rules -> New Rule -> Port -> 4444 -> Priv,Pub -> save

# Get network interface IP

EXTERNAL_IP=$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $2}')
# to enable redirecting to localhost
sysctl -w net.ipv4.conf.eth0.route_localnet=1
iptables -t nat -A OUTPUT -o lo -d 127.0.0.1 -p tcp --dport 4444 -j DNAT  --to-destination $EXTERNAL_IP:4444

# NOTE: To delete iptables entry run the same command but with '-D' flag instead of '-A' 
```

