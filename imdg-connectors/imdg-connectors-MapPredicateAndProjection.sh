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

function check_chosen_tickers {
    INITIAL_STRING=$1
    RESULT_LIST_ITEMS=$(grep "${INITIAL_STRING}" ${OUTPUT_LOG_FILE})

    if [ "x${RESULT_LIST_ITEMS}" == "x" ]; then   
        echo "'${INITIAL_STRING}' has not been found in output log.";
        exit 1
    fi

    for i in {0..9}; do
        EXPECTED_ITEM=ticker-$i
        echo "Checking log for item '${EXPECTED_ITEM}' for '${INITIAL_STRING}'"
        EXPECTED_ITEM_COUNT=$(grep $EXPECTED_ITEM <<< "$RESULT_LIST_ITEMS" | wc -l)
        if [ ${EXPECTED_ITEM_COUNT} -ne 1 ]; then   
            echo "Ticker '${EXPECTED_ITEM}' for '${INITIAL_STRING}' is missing in output log.";
            exit 1
        fi
    done
}

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/imdg-connectors
mvn "-Dexec.args=-classpath %classpath com.hazelcast.samples.jet.imdg.MapPredicateAndProjection" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "Creating 100000 entries..."
check_text_in_log "Executing job 1..."
check_text_in_log "Executing job 2..."
check_chosen_tickers "Sink items using predicates and projections:"
check_chosen_tickers "Sink items using lambdas:"


