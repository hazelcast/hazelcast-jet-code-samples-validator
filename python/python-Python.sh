#!/bin/bash

export SCRIPT_WORKSPACE=$1
export JET_REPO=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log

function check_text_in_log {
    EXPECTED_TEXT=$1
    echo "Checking log for '${EXPECTED_TEXT}'"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${OUTPUT_LOG_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -lt 1 ]; then   
        echo "Log '${EXPECTED_TEXT}' has not been found in ${OUTPUT_LOG_FILE}.";
        exit 1
    fi
}

function kill_process {
    TO_KILL=$1
    echo "Searching for PID of process '${TO_KILL}'"
    jps -m
    PID_TO_KILL=$(jps | grep "${TO_KILL}" | awk '{print $1}')
    echo "Killing process '${PID_TO_KILL}'"
    kill -9 ${PID_TO_KILL}
}

cd ${JET_REPO}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${JET_REPO}/examples/python
mvn "-Dexec.args=-classpath %classpath com.hazelcast.jet.examples.python.Python" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE} &
sleep 180

# kill Jet
kill_process "Python"
sleep 5

#################################
### verify code sample output ###
#################################
check_text_in_log "Started Python process: java.lang.UNIXProcess"
check_text_in_log "Python process java.lang.UNIXProcess.* listening on port "
