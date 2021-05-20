#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log

function check_text_in_log {
    EXPECTED_TEXT=$1
    EXPECTED_AT_LEAST=$2
    echo "Checking that '${EXPECTED_TEXT}' occurs for at least ${EXPECTED_AT_LEAST} times"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${OUTPUT_LOG_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -lt ${EXPECTED_AT_LEAST} ]; then   
        echo "Log '${EXPECTED_TEXT}' has not been found in output log for at least ${EXPECTED_AT_LEAST} times.";
        exit 1
    fi
}

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/jms
mvn "-Dexec.args=-classpath %classpath com.hazelcast.samples.jet.jms.JmsTopicSample" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "Output to ordinal 0: Message-[0-9]" 5

