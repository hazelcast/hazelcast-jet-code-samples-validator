#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export OUTPUT_SESSIONS_LOG_FILE=${SCRIPT_WORKSPACE}/output_sessions.log

function check_text_in_session_log {
    EXPECTED_TEXT=$1
    echo "Checking log for '${EXPECTED_TEXT}'"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${OUTPUT_SESSIONS_LOG_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -lt 1 ]; then   
        echo "Log '${EXPECTED_TEXT}' has not been found in output log.";
        exit 1
    fi
}

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/session-windows
mvn "-Dexec.args=-classpath %classpath com.hazelcast.samples.jet.sessionwindow.SessionWindow" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
grep "Session{userId=" ${OUTPUT_LOG_FILE} | tee ${OUTPUT_SESSIONS_LOG_FILE}

EXPECTED_SESSION_LOG_COUNT=$(wc -l ${OUTPUT_SESSIONS_LOG_FILE} | awk '{ print $1 }')
if [ ${EXPECTED_SESSION_LOG_COUNT} -lt 1 ]; then   
    echo "Session log is empty.";
    exit 1
fi

SESSION_LOG_COUNT_WITH_MS=$(grep "Session{userId=user[0-9]\{3\}, start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, duration=[0-9 ][0-9]s, value={viewed=[0-9 ][0-9], purchases=\[.*\]}" ${OUTPUT_SESSIONS_LOG_FILE} | wc -l)
SESSION_LOG_COUNT_WITHOUT_MS=$(grep "Session{userId=user[0-9]\{3\}, start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\, duration=[0-9 ][0-9]s, value={viewed=[0-9 ][0-9], purchases=\[.*\]}" ${OUTPUT_SESSIONS_LOG_FILE} | wc -l)
SESSION_LOG_COUNT=$((${SESSION_LOG_COUNT_WITH_MS}+${SESSION_LOG_COUNT_WITHOUT_MS}))
if [ ${SESSION_LOG_COUNT} -ne ${EXPECTED_SESSION_LOG_COUNT} ]; then   
    echo "There is unexpected session log.";
    exit 1
fi

check_text_in_session_log "purchases=\[product[0-9]"


