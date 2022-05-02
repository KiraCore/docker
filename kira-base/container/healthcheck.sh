#!/usr/bin/env bash
set +e && source $ETC_PROFILE &>/dev/null && set -e
# FILE="${SELF_CONTAINER}/healthcheck.sh" && rm $FILE && nano $FILE && chmod 555 $FILE
set -x

echoInfo "INFO: Staring $NODE_TYPE healthcheck $KIRA_SETUP_VER ..." >> ${COMMON_LOGS}/health.log

if [ "${NODE_TYPE,,}" == "sentry" ] || [ "${NODE_TYPE,,}" == "seed" ]; then
    /bin/sh -c "/bin/bash ${COMMON_DIR}/sentry/healthcheck.sh | tee -a ${COMMON_LOGS}/health.log ; test ${PIPESTATUS[0]} = 0"
elif [ "${NODE_TYPE,,}" == "validator" ]; then
    /bin/sh -c "/bin/bash ${COMMON_DIR}/validator/healthcheck.sh | tee -a ${COMMON_LOGS}/health.log ; test ${PIPESTATUS[0]} = 0"
elif [ "${NODE_TYPE,,}" == "interx" ]; then
    /bin/sh -c "/bin/bash ${COMMON_DIR}/interx/healthcheck.sh | tee -a ${COMMON_LOGS}/health.log ; test ${PIPESTATUS[0]} = 0"
else
    echoErr "ERROR: Unknown node type '$NODE_TYPE'" >> ${COMMON_LOGS}/health.log
fi

