FROM ghcr.io/kiracore/docker/base-image:main

# Local Update
# (rm -fv $KIRA_INFRA/docker/base-image/Dockerfile) && nano $KIRA_INFRA/docker/base-image/Dockerfile

ADD ./container ${SELF_CONTAINER}

RUN chmod -R 777 ${SELF_HOME} && chmod 555 ${ETC_PROFILE} && chmod 555 ${BASHRC}

ARG DEBIAN_FRONTEND=noninteractive
RUN LC_ALL=C ${BUILD_SCRIPT} && rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PORT="8080"
ENV CORSANYWHERE_WHITELIST="https://*.kira.network,http://*.kira.network"

ENTRYPOINT [ "node", "/node_modules/cors-anywhere/server.js" ] 