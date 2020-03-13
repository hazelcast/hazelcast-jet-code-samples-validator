#!/bin/bash

export SCRIPT_WORKSPACE=$1
export JET_REPO=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log

function check_text_in_log {
    EXPECTED_TEXT=$1
    echo "Checking log for '${EXPECTED_TEXT}'"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${OUTPUT_LOG_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -ne 1 ]; then   
        echo "Unexpected count of '${EXPECTED_TEXT}' has not been found in output log. Expected: ${EXPECTED_COUNT} was: ${EXPECTED_TEXT_COUNT}";
        exit 1
    fi
}

function check_certain_enrichment {
    CHECKED_ID=$1
    EXPECTED_VALUE=$2
    OUTPUT_LOG_FILE=$3
    OUTPUT_LOG_FILE_TMP=${OUTPUT_LOG_FILE}_tmp
    echo "Checking enrichment for '${CHECKED_ID}' in '${OUTPUT_LOG_FILE}' ..."
    grep "${CHECKED_ID}" ${OUTPUT_LOG_FILE} > ${OUTPUT_LOG_FILE_TMP}
    CHECKED_ID_COUNT=$(grep "${CHECKED_ID}" ${OUTPUT_LOG_FILE_TMP} | wc -l)
    EXPECTED_VALUE_COUNT=$(grep "${EXPECTED_VALUE}" ${OUTPUT_LOG_FILE_TMP} | wc -l)
    if [ ${CHECKED_ID_COUNT} -ne ${EXPECTED_VALUE_COUNT} ]; then
        echo "There is Trade with '${CHECKED_ID}' which does not include '${EXPECTED_VALUE}' in '${OUTPUT_LOG_FILE}'";
        exit 1
    fi     
}

# check whether log contains some trades and that various Product/Brokers are generated 
function check_trades_are_generated_and_processed {
    echo "Checking various Product/Brokers trades are generated in '${OUTPUT_LOG_FILE}' ..."
    PRODUCTS_COUNTER=0
    BROKERS_COUNTER=0
    occurs_in_log ${OUTPUT_LOG_FILE} "productId=31"
    PRODUCTS_COUNTER=$((${PRODUCTS_COUNTER}+$?))
    occurs_in_log ${OUTPUT_LOG_FILE} "productId=32"
    PRODUCTS_COUNTER=$((${PRODUCTS_COUNTER}+$?))
    occurs_in_log ${OUTPUT_LOG_FILE} "productId=33"
    PRODUCTS_COUNTER=$((${PRODUCTS_COUNTER}+$?))
    occurs_in_log ${OUTPUT_LOG_FILE} "productId=34"
    PRODUCTS_COUNTER=$((${PRODUCTS_COUNTER}+$?))
    occurs_in_log ${OUTPUT_LOG_FILE} "brokerId=21"
    BROKERS_COUNTER=$((${BROKERS_COUNTER}+$?))
    occurs_in_log ${OUTPUT_LOG_FILE} "brokerId=22"
    BROKERS_COUNTER=$((${BROKERS_COUNTER}+$?))
    occurs_in_log ${OUTPUT_LOG_FILE} "brokerId=23"
    BROKERS_COUNTER=$((${BROKERS_COUNTER}+$?))
    occurs_in_log ${OUTPUT_LOG_FILE} "brokerId=24"
    BROKERS_COUNTER=$((${BROKERS_COUNTER}+$?))
    if [ ${PRODUCTS_COUNTER} -lt 2 ]; then   
        echo "At least two different Products should occur in log '${OUTPUT_LOG_FILE}'";
        exit 1
    fi    
    if [ ${BROKERS_COUNTER} -lt 2 ]; then   
        echo "At least two different Brokers should occur in log '${OUTPUT_LOG_FILE}'";
        exit 1
    fi 
}

function occurs_in_log {
    OUTPUT_LOG_FILE=$1
    CHECKED_TEXT=$2
    OCCURED_COUNT=$(grep "${CHECKED_TEXT}" ${OUTPUT_LOG_FILE} | wc -l)
    if [ ${OCCURED_COUNT} -gt 0 ]; then   
        return 1
    fi
    return 0
}

cd ${JET_REPO}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${JET_REPO}/examples/grpc
mvn "-Dexec.args=-classpath %classpath com.hazelcast.jet.examples.grpc.GRPCEnrichment" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "Stopped trade events"
check_certain_enrichment "productId=31" "US 1Y Bond" ${OUTPUT_LOG_FILE}
check_certain_enrichment "productId=32" "US 10Y Bond" ${OUTPUT_LOG_FILE}
check_certain_enrichment "productId=33" "UK 1Y Bond" ${OUTPUT_LOG_FILE}
check_certain_enrichment "productId=34" "UK 10Y Bond" ${OUTPUT_LOG_FILE}
check_certain_enrichment "brokerId=21" "Donte Biermann" ${OUTPUT_LOG_FILE}
check_certain_enrichment "brokerId=22" "Hunter Jurado" ${OUTPUT_LOG_FILE}
check_certain_enrichment "brokerId=23" "Rebbecca Prosper" ${OUTPUT_LOG_FILE}
check_certain_enrichment "brokerId=24" "Kisha Agena" ${OUTPUT_LOG_FILE}
check_trades_are_generated_and_processed

