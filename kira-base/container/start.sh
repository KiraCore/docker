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
        echoInfo "INFO: Ensuring that sekaid & interx processes are killed"
        globSet HALT_TASK true
        pkill -15 sekaid || echoWarn "WARNING: Failed to kill sekaid process (-15)"
        pkill -9 interxd || echoWarn "WARNING: Failed to kill interx process (-9)"
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
