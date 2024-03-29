#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log

function check_text_in_log {
    EXPECTED_TEXT=$1
    echo "Checking log for '${EXPECTED_TEXT}'"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${OUTPUT_LOG_FILE} | wc -l)
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
cd ${CODE_SAMPLES_HOME}/jet/hazelcast-connectors
mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.connectors.RemoteListSourceAndSink" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "Creating and populating remote Hazelcast instance..."
check_text_in_log "Local list-1 contents: \[0, 1, 2, 3, 4, 5, 6, 7, 8, 9\]"
check_text_in_log "Remote list-2 contents: \[0, 1, 2, 3, 4, 5, 6, 7, 8, 9\]"

