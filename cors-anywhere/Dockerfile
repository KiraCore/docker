FROM localhost:5000/base-image:${REF_GITHUB_BRNACH}
# ghcr.io/kiracore/docker/base-image:${REF_GITHUB_BRNACH}

# Local Update
# (rm -fv $KIRA_INFRA/docker/base-image/Dockerfile) && nano $KIRA_INFRA/docker/base-image/Dockerfile

ENV SELF_HOME=/self/home
ENV SELF_CONTAINER=${SELF_HOME}/container
ENV BUILD_SCRIPT=${SELF_CONTAINER}/deployment.sh

RUN mkdir -p ${SELF_CONTAINER} 

ADD ./container ${SELF_CONTAINER}

RUN chmod -R 777 ${SELF_HOME}

ARG DEBIAN_FRONTEND=noninteractive
RUN LC_ALL=C ${BUILD_SCRIPT} && rm -rf /var/lib/apt/lists/*

ENV PORT="8080"
ENV CORSANYWHERE_WHITELIST="https://*.kira.network,http://*.kira.network"

ENTRYPOINT [ "node", "/node_modules/cors-anywhere/server.js" ] 