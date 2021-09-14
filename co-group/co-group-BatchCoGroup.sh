#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log

function check_text_in_log {
    EXPECTED_TEXT=$1
    EXPECTED_COUNT=${2:-1}
    echo "Checking log for '${EXPECTED_TEXT}'"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${OUTPUT_LOG_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -ne ${EXPECTED_COUNT} ]; then   
        echo "Unexpected count of '${EXPECTED_TEXT}' has not been found in output log. Expected: ${EXPECTED_COUNT} was: ${EXPECTED_TEXT_COUNT}";
        exit 1
    fi
}

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/co-group
mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.cogroup.BatchCoGroup" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "addToCart:$"
check_text_in_log "AddToCart{quantity=21, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "AddToCart{quantity=22, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "AddToCart{quantity=23, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "AddToCart{quantity=24, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "payment:$"
check_text_in_log "Payment{amount=31, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "Payment{amount=32, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "Payment{amount=33, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "Payment{amount=34, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "pageVisit:$"
check_text_in_log "PageVisit{loadTime=1, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "PageVisit{loadTime=2, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "PageVisit{loadTime=3, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "PageVisit{loadTime=4, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}$"
check_text_in_log "result:" 2
check_text_in_log "12->(\[PageVisit{loadTime=3, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}, PageVisit{loadTime=4, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}\], \[AddToCart{quantity=23, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}, AddToCart{quantity=24, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}\], \[Payment{amount=33, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}, Payment{amount=34, userId=12, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}\])" 2
check_text_in_log "11->(\[PageVisit{loadTime=1, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}, PageVisit{loadTime=2, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}\], \[AddToCart{quantity=21, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}, AddToCart{quantity=22, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}\], \[Payment{amount=31, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}, Payment{amount=32, userId=11, timestamp=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}}\])" 2
check_text_in_log "BatchCoGroup results are valid" 2

