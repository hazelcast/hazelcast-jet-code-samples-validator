#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export JSON_DATA_FILE=${CODE_SAMPLES_HOME}/jet/files/data/sales.json
export SOURCE_DIRECTORY=${CODE_SAMPLES_HOME}/jet/files/data/jsonData

function check_text_in_log {
    EXPECTED_TEXT=$1
    echo "Checking log for '${EXPECTED_TEXT}'"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${OUTPUT_LOG_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -lt 1 ]; then   
        echo "Log '${EXPECTED_TEXT}' has not been found in output log.";
        exit 1
    fi
}

mkdir ${SOURCE_DIRECTORY}
cp ${JSON_DATA_FILE} ${SOURCE_DIRECTORY}

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/files
mvn "-Dexec.args=-classpath %classpath com.hazelcast.samples.jet.files.SalesJsonAnalyzer ${SOURCE_DIRECTORY}" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "diners-club-enroute=6"
check_text_in_log "solo=1"
check_text_in_log "china-unionpay=3"
check_text_in_log "diners-club-carte-blanche=6"
check_text_in_log "mastercard=11"
check_text_in_log "jcb=33"
check_text_in_log "bankcard=4"
check_text_in_log "americanexpress=5"
check_text_in_log "maestro=15"
check_text_in_log "diners-club-international=3"
check_text_in_log "diners-club-us-ca=2"
check_text_in_log "visa=2"
check_text_in_log "visa-electron=6"
check_text_in_log "switch=5"

