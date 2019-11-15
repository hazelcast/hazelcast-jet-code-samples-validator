#!/bin/bash

export SCRIPT_WORKSPACE=$1
export JET_REPO=$2

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

cd ${JET_REPO}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${JET_REPO}/examples/wordcount
mvn "-Dexec.args=-classpath %classpath com.hazelcast.jet.examples.wordcount.WordCount" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "done in [0-9]* milliseconds. Top 100 entries are:"
check_text_in_log "| 27843 | the     |"
check_text_in_log "|  5910 | have    |"
check_text_in_log "|  1340 | some    |"
check_text_in_log "Count of 'the' is valid"


