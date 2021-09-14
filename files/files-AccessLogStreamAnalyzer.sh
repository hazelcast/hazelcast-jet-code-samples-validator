#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log

function check_text_in_log {
    EXPECTED_TEXT=$1
    EXPECTED_AT_LEAST=$2
    echo "Checking log for '${EXPECTED_TEXT}'"
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
cd ${CODE_SAMPLES_HOME}/jet/files
mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.files.AccessLogStreamAnalyzer" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
for i in {0..10}; do
    check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='/article$i', value='[0-9]*', isEarly=false}" 60
done

