#!/bin/bash
# quick edit: FILE="$HOME/start.sh" && rm -fv $FILE && nano $FILE && chmod 555 $FILE
set -x

# NOTE: This is example of the local deployment for TESTING purpouses only !!!

apt-get update -y
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    software-properties-common apt-transport-https ca-certificates gnupg curl wget git unzip build-essential \
    nghttp2 libnghttp2-dev libssl-dev fakeroot dpkg-dev libcurl4-openssl-dev net-tools jq aptitude

apt update -y
apt install -y bc dnsutils psmisc netcat

apt-get update -y --fix-missing
apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages \
  python \
  python3 \
  python3-pip \
  software-properties-common \
  tar \
  zip \
  jq \
  php-cli \
  unzip \
  php7.4-gmp \
  php-mbstring \
  md5deep \
  sysstat \
  htop

echo "INFO: Attempting to remove old docker..."
service docker stop || echo "WARNING: Failed to stop docker servce"
apt remove --purge docker -y || echo "WARNING: Failed to remove docker"
apt remove --purge containerd -y || echo "WARNING: Failed to remove containerd"
apt remove --purge runc -y || echo "WARNING: Failed to remove runc"
apt remove --purge docker-engine -y || echo "WARNING: Failed to remove docker-engine"
apt remove --purge docker.io -y || echo "WARNING: Failed to remove docker.io"
apt remove --purge docker.io -y || echo "WARNING: Failed to remove docker.io"
apt remove --purge docker-ce -y || echo "WARNING: Failed to remove docker-ce"
apt remove --purge docker-ce-cli -y || echo "WARNING: Failed to remove docker-ce-cli"
apt remove --purge containerd.io -y || echo "WARNING: Failed to remove containerd.io"
apt autoremove -y || echo "WARNING: Failed autoremove"
rm -rfv /etc/docker
rm -rfv /var/lib/docker

echo "INFO: Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-get update
#apt install docker-ce docker-ce-cli containerd.io -y
apt install containerd docker.io -y

DOCKER_DAEMON_JSON="/etc/docker/daemon.json"
rm -f -v $DOCKER_DAEMON_JSON
cat >$DOCKER_DAEMON_JSON <<EOL
{
  "dns": ["1.1.1.1", "8.8.8.8"]
}
EOL

systemctl enable --now docker
docker -v

echo "INFO: Cleaning up dangling volumes..."
docker volume ls -qf dangling=true | xargs -r docker volume rm || echo "INFO: Failed to remove dangling vomues!"

CONTAINER_NAME="cors-anywhere" 
id=$(docker ps --no-trunc -aqf "name=^${CONTAINER_NAME}$" 2> /dev/null || echo "")
docker container kill $id || echo "WARNING: Container $id is not running"
docker rm $id || echo "WARNING: Failed to remove container $id"

PORT=8080

docker run -d \
    -p $PORT:$PORT \
    -e CONTAINER_NAME="$CONTAINER_NAME" \
    -e PORT="$PORT" \
    -e CORSANYWHERE_WHITELIST="" \
    --name $CONTAINER_NAME \
    --restart=always \
    --log-opt max-size=5m \
    --log-opt max-file=5 \
    kiracore/docker:main-cors-anywhere

systemctl daemon-reload
systemctl restart docker || ( journalctl -u docker | tail -n 10 && systemctl restart docker )

docker ps
docker logs -f $CONTAINER_NAME

#  docker exec -it $(docker ps --no-trunc -aqf "name=^${CONTAINER_NAME}$") bash 