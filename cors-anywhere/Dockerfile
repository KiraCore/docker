FROM ubuntu:20.04
# ghcr.io/kiracore/docker/base-image:v0.0.4.0
 
# Local Update
# (rm -fv $KIRA_INFRA/docker/base-image/Dockerfile) && nano $KIRA_INFRA/docker/base-image/Dockerfile

ENV SELF_HOME=/self/home
ENV SELF_CONTAINER=${SELF_HOME}/container
ENV BUILD_SCRIPT=${SELF_CONTAINER}/deployment.sh

ADD ./container ${SELF_CONTAINER}

RUN chmod -R 777 ${SELF_HOME}

ARG DEBIAN_FRONTEND=noninteractive
RUN LC_ALL=C ${BUILD_SCRIPT} && rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PORT="8080"
ENV CORSANYWHERE_WHITELIST="https://*.kira.network,http://*.kira.network"

ENTRYPOINT [ "node", "/node_modules/cors-anywhere/server.js" ] 