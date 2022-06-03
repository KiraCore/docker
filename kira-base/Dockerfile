FROM ubuntu:20.04

# Local Update
# (rm -fv $KIRA_INFRA/docker/base-image/Dockerfile) && nano $KIRA_INFRA/docker/base-image/Dockerfile

ENV JOURNAL_LOGS="/var/log/journal"
ENV COMMON_DIR="/common"
ENV COMMON_READ="/common_ro"
ENV GLOBAL_COMMON="${COMMON_DIR}/kiraglob"
ENV GLOBAL_COMMON_RO="${COMMON_READ}/kiraglob"
ENV SNAP_DIR="/snap"
ENV ETC_PROFILE="/etc/profile"

# Env necessary for the individual child container setup
ENV SELF_HOME=/self/home
ENV SELF_SCRIPTS=${SELF_HOME}/scripts
ENV SELF_CONFIGS=${SELF_HOME}/configs
ENV SELF_UPDATE=${SELF_HOME}/update
ENV SELF_UPDATE_TMP=${SELF_HOME}/tmp/update
ENV SELF_CONTAINER=${SELF_HOME}/container
ENV START_SCRIPT=${SELF_CONTAINER}/start.sh
ENV BUILD_SCRIPT=${SELF_CONTAINER}/deployment.sh
ENV HEALTHCHECK_SCRIPT=${SELF_CONTAINER}/healthcheck.sh

ENV SEKAID_HOME=/root/.sekai
ENV INTERXD_HOME=/root/.interx
ENV SEKAID_CONFIG="${SEKAID_HOME}/config"
ENV SEKAID_DATA="${SEKAID_HOME}/data"

ENV KIRA_BIN="/usr/kira/bin"
ENV KEYS_DIR="/usr/keys"
ENV KIRA_HOME="/home/kira"
ENV KIRA_COSIGN_PUB="${KEYS_DIR}/kira-cosign.pub"
ENV PATH="${PATH}:${KIRA_BIN}"
ENV COMMON_LOGS="${COMMON_DIR}/logs"

RUN mkdir -p ${KIRA_HOME} ${GLOBAL_COMMON} ${GLOBAL_COMMON_RO} ${KEYS_DIR} ${SELF_CONTAINER} ${KIRA_BIN} ${COMMON_READ} ${SNAP_DIR} ${SELF_HOME} ${SELF_SCRIPTS} ${SELF_CONFIGS} ${SELF_UPDATE} ${SELF_UPDATE_TMP} ${SEKAID_HOME} ${INTERXD_HOME} ${COMMON_DIR}

ADD ./container ${SELF_CONTAINER}

RUN chmod -Rv 777 ${SELF_HOME}

ARG DEBIAN_FRONTEND=noninteractive
RUN LC_ALL=C ${BUILD_SCRIPT} && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=60s --timeout=600s --start-period=600s --retries=4 CMD ${HEALTHCHECK_SCRIPT}

CMD ["sh", "-c", "/bin/bash ${START_SCRIPT} | tee -a ${COMMON_LOGS}/start.log ; test ${PIPESTATUS[0]} = 0"]
