#!/usr/bin/env bash
set +e && source $ETC_PROFILE &>/dev/null && set -e
set -x

KIRA_SETUP_VER=$(globGet KIRA_SETUP_VER "$GLOBAL_COMMON_RO")

echoInfo "INFO: Staring $NODE_TYPE container $KIRA_SETUP_VER ..."
timerStart "catching_up"
timerStart "success"

RESTART_COUNTER=$(globGet RESTART_COUNTER)
if ($(isNaturalNumber $RESTART_COUNTER)) ; then
    globSet RESTART_COUNTER "$(($RESTART_COUNTER+1))"
    globSet RESTART_TIME "$(date -u +%s)"
fi

while [ "$(globGet HALT_TASK)" == "true" ] || [ "$(globGet EXIT_TASK)" == "true" ] ; do
    if [ "$(globGet EXIT_TASK)" == "true" ] ; then
        echoInfo "INFO: Ensuring that ${NODE_TYPE,,} processes is killed"
        globSet HALT_TASK true
        if [ "${NODE_TYPE,,}" == "sentry" ] || [ "${NODE_TYPE,,}" == "seed" ] || [ "${NODE_TYPE,,}" == "validator" ]; then
           pkill -15 sekaid || ( echoWarn "WARNING: Failed to kill sekaid process" >> ${COMMON_LOGS}/health.log )
        elif [ "${NODE_TYPE,,}" == "interx" ]; then
             pkill -9 interx || ( echoWarn "WARNING: Failed to kill interx process" >> ${COMMON_LOGS}/health.log )
        elif [ "${NODE_TYPE,,}" == "bitcoin" ]; then
            bitcoin-cli -datadir=$BITCOIN_DATA stop || ( echoWarn "WARNING: Failed to bitcoin-cli stop bitcoind process" >> ${COMMON_LOGS}/health.log )
        else
            echoErr "ERROR: Unknown node type '$NODE_TYPE', process can NOT be killed!" >> ${COMMON_LOGS}/health.log
        fi
        globSet EXIT_TASK false
    fi
    echoInfo "INFO: Waiting for container to be unhalted..."
    sleep 30
done

globSet CFG_TASK "true"
FAILED="false"
if [ "${NODE_TYPE,,}" == "sentry" ] || [ "${NODE_TYPE,,}" == "seed" ]; then
    $COMMON_DIR/sentry/start.sh || FAILED="true"
elif [ "${NODE_TYPE,,}" == "validator" ]; then
    $COMMON_DIR/validator/start.sh || FAILED="true"
elif [ "${NODE_TYPE,,}" == "interx" ]; then
    $COMMON_DIR/interx/start.sh || FAILED="true"
elif [ "${NODE_TYPE,,}" == "bitcoin" ]; then
    $COMMON_DIR/bitcoin/start.sh || FAILED="true"
else
    echoErr "ERROR: Unknown node type '$NODE_TYPE'"
    FAILED="true"
fi

globSet CFG_TASK "false"
if [ "${FAILED,,}" == "true" ] ; then
    echoErr "ERROR: $NODE_TYPE node startup failed"
    sleep 3
    exit 1
fi
