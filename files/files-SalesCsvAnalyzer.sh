#!/bin/bash

export SCRIPT_WORKSPACE=$1
export JET_REPO=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export SOURCE_DIRECTORY=${JET_REPO}/examples/files/data

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
cd ${JET_REPO}/examples/files
mvn "-Dexec.args=-classpath %classpath com.hazelcast.jet.examples.files.SalesCsvAnalyzer ${SOURCE_DIRECTORY}" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "diners-club-enroute=3"
check_text_in_log "solo=3"
check_text_in_log "china-unionpay=6"
check_text_in_log "diners-club-carte-blanche=6"
check_text_in_log "mastercard=9"
check_text_in_log "laser=3"
check_text_in_log "jcb=65"
check_text_in_log "bankcard=8"
check_text_in_log "americanexpress=4"
check_text_in_log "maestro=11"
check_text_in_log "diners-club-international=2"
check_text_in_log "diners-club-us-ca=2"
check_text_in_log "instapayment=4"
check_text_in_log "visa=2"
check_text_in_log "visa-electron=6"
check_text_in_log "switch=4"

