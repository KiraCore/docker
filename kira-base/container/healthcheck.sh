#!/usr/bin/env bash
set +e && source $ETC_PROFILE &>/dev/null && set -e
# FILE="${SELF_CONTAINER}/healthcheck.sh" && rm $FILE && nano $FILE && chmod 555 $FILE
set -x

KIRA_SETUP_VER=$(globGet KIRA_SETUP_VER "$GLOBAL_COMMON_RO")
HALT_TASK=$(globGet HALT_TASK) && [ "${HALT_TASK,,}" != "true" ] && HALT_TASK="false"
EXIT_TASK=$(globGet EXIT_TASK) && [ "${EXIT_TASK,,}" != "true" ] && EXIT_TASK="false"
CFG_TASK=$(globGet CFG_TASK) && [ "${CFG_TASK,,}" != "true" ] && CFG_TASK="false"
INIT_DONE=$(globGet INIT_DONE) && [ "${INIT_DONE,,}" != "true" ] && INIT_DONE="false"

echoInfo "---------------------------------------------------" >> ${COMMON_LOGS}/health.log
echoInfo "| STARTING ${NODE_TYPE^^} NODE HEALTH CHECK $KIRA_SETUP_VER ..." >> ${COMMON_LOGS}/health.log
echoInfo "|--------------------------------------------------" >> ${COMMON_LOGS}/health.log
echoInfo "|      Hatling: $HALT_TASK" >> ${COMMON_LOGS}/health.log
echoInfo "|      Exiting: $HALT_TASK" >> ${COMMON_LOGS}/health.log
echoInfo "|  Configuring: $HALT_TASK" >> ${COMMON_LOGS}/health.log
echoInfo "| Initializing: $HALT_TASK" >> ${COMMON_LOGS}/health.log
echoInfo "---------------------------------------------------" >> ${COMMON_LOGS}/health.log

echoInfo "INFO: Logs cleanup..."
find "$COMMON_LOGS" -type f -size +16M -exec truncate --size=8M {} + || ( echoWarn "WARNING: Failed to truncate common logs" >> ${COMMON_LOGS}/health.log )
journalctl --vacuum-time=3d --vacuum-size=32M || ( echoWarn "WARNING: journalctl vacuum failed" >> ${COMMON_LOGS}/health.log )
find "/var/log" -type f -size +64M -exec truncate --size=8M {} + || ( echoWarn "WARNING: Failed to truncate system logs" >> ${COMMON_LOGS}/health.log )
echoInfo "INFO: Logs cleanup finalized"

if [ "${EXIT_TASK,,}" == "true" ]; then
    echoInfo "INFO: Ensuring interx process is killed, process exit was requested" >> ${COMMON_LOGS}/health.log
    globSet HALT_TASK "true"
    pkill -15 sekaid || ( echoWarn "WARNING: Failed to kill sekaid process" >> ${COMMON_LOGS}/health.log )
    pkill -9 interx || ( echoWarn "WARNING: Failed to kill interx process" >> ${COMMON_LOGS}/health.log )
    globSet EXIT_TASK "false"
fi

if [ "${HALT_TASK,,}" == "true" ] || [ "${CFG_TASK,,}" == "true" ] || [ "${INIT_DONE,,}" == "false" ] ; then
    [ "${HALT_TASK,,}" == "true" ] && echoWarn "WARNING: Contianer is halted, NO health checks will be executed!" >> ${COMMON_LOGS}/health.log
    [ "${CFG_TASK,,}" == "true" ] && echoWarn "WARNING: Contianer is being configured, NO health checks will be executed!" >> ${COMMON_LOGS}/health.log
    [ "${INIT_DONE,,}" == "false" ] && echoWarn "WARNING: Contianer is being initalized, NO health checks will be executed!" >> ${COMMON_LOGS}/health.log
    globSet EXTERNAL_STATUS "OFFLINE"
    sleep 5
    exit 0
fi

if [ "${NODE_TYPE,,}" == "sentry" ] || [ "${NODE_TYPE,,}" == "seed" ]; then
    /bin/sh -c "/bin/bash ${COMMON_DIR}/sentry/healthcheck.sh 2>&1 | tee -a ${COMMON_LOGS}/health.log ; test ${PIPESTATUS[0]} = 0"
elif [ "${NODE_TYPE,,}" == "validator" ]; then
    /bin/sh -c "/bin/bash ${COMMON_DIR}/validator/healthcheck.sh 2>&1 | tee -a ${COMMON_LOGS}/health.log ; test ${PIPESTATUS[0]} = 0"
elif [ "${NODE_TYPE,,}" == "interx" ]; then
    /bin/sh -c "/bin/bash ${COMMON_DIR}/interx/healthcheck.sh 2>&1 | tee -a ${COMMON_LOGS}/health.log ; test ${PIPESTATUS[0]} = 0"
else
    echoErr "ERROR: Unknown node type '$NODE_TYPE'" >> ${COMMON_LOGS}/health.log
fi
