FROM ubuntu:20.04

# Local Update
# (rm -fv $KIRA_INFRA/docker/base-image/Dockerfile) && nano $KIRA_INFRA/docker/base-image/Dockerfile

ENV JOURNAL_LOGS="/var/log/journal"
ENV COMMON_DIR="/common"
ENV COMMON_READ="/common_ro"
ENV GLOBAL_COMMON_RO="/common_ro/kiraglob"
ENV SNAP_DIR="/snap"

# Env necessary for the individual child container setup
ENV SELF_HOME=/self/home
ENV SELF_LOGS=/self/logs
ENV SELF_SCRIPTS=${SELF_HOME}/scripts
ENV SELF_CONFIGS=${SELF_HOME}/configs
ENV SELF_UPDATE=${SELF_HOME}/update
ENV SELF_UPDATE_TMP=${SELF_HOME}/tmp/update
ENV SELF_CONTAINER=${SELF_HOME}/container
ENV START_SCRIPT=${SELF_CONTAINER}/start.sh
ENV BUILD_SCRIPT=${SELF_CONTAINER}/deployment.sh
ENV HEALTHCHECK_SCRIPT=${SELF_CONTAINER}/healthcheck.sh
ENV ON_FAILURE_SCRIPT=${SELF_CONTAINER}/on_failure.sh
ENV ON_INIT_SCRIPT=${SELF_CONTAINER}/on_init.sh
ENV ON_SUCCESS_SCRIPT=${SELF_CONTAINER}/on_success.sh
ENV INIT_START_FILE=${SELF_HOME}/init_start
ENV INIT_END_FILE=${SELF_HOME}/init_end
ENV FAILURE_START_FILE=${SELF_HOME}/failure_start
ENV FAILURE_END_FILE=${SELF_HOME}/failure_end
ENV SUCCESS_START_FILE=${SELF_HOME}/success_start
ENV SUCCESS_END_FILE=${SELF_HOME}/success_end
ENV MAINTENANCE_FILE=${SELF_HOME}/maintenence

ENV SEKAID_HOME=/root/.sekaid
ENV INTERX_HOME=/root/.interx
ENV SEKAID_CONFIG="${SEKAID_HOME}/config"
ENV SEKAID_DATA="${SEKAID_HOME}/data"

ENV KIRA_BIN="/usr/kira/bin"
ENV KEYS_DIR="/usr/keys"
ENV KIRA_COSIGN_PUB="/usr/keys/kira-cosign.pub"
ENV CDHELPER_DIR="/usr/local/bin/CDHelper"
ENV PATH="${PATH}:${KIRA_BIN}:${CDHELPER_DIR}"
ENV COMMON_LOGS="${COMMON_DIR}/logs"

RUN mkdir -p ${KEYS_DIR} ${CDHELPER_DIR} ${SELF_CONTAINER} ${KIRA_BIN} ${COMMON_READ} ${SNAP_DIR} ${SELF_HOME} ${SELF_SCRIPTS} ${SELF_CONFIGS} ${SELF_UPDATE} ${SELF_UPDATE_TMP} ${SELF_LOGS} ${SEKAID_HOME} ${INTERX_HOME} ${COMMON_DIR}

ADD ./container ${SELF_CONTAINER}

RUN chmod -Rv 777 ${SELF_HOME}

ARG DEBIAN_FRONTEND=noninteractive
RUN LC_ALL=C ${BUILD_SCRIPT} && rm -rf /var/lib/apt/lists/*