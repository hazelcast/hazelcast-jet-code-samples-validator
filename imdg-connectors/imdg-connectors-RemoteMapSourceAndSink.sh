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

function check_map_content {
    INITIAL_STRING=$1
    RESULT_MAP_ITEMS=$(grep "${INITIAL_STRING}" ${OUTPUT_LOG_FILE})

    if [ "x${RESULT_MAP_ITEMS}" == "x" ]; then   
        echo "'${INITIAL_STRING}' has not been found in output log.";
        exit 1
    fi

    for i in {0..9}; do
        EXPECTED_ENTRY="$i=$i"
        echo "Checking log for entry '${EXPECTED_ENTRY}' for '${INITIAL_STRING}'"
        EXPECTED_ENTRY_COUNT=$(grep $EXPECTED_ENTRY <<< "$RESULT_MAP_ITEMS" | wc -l)
        if [ ${EXPECTED_ENTRY_COUNT} -ne 1 ]; then   
            echo "Entry '${EXPECTED_ENTRY}' for '${INITIAL_STRING}' is missing in output log.";
            exit 1
        fi
    done
}

cd ${JET_REPO}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${JET_REPO}/examples/imdg-connectors
mvn "-Dexec.args=-classpath %classpath com.hazelcast.jet.examples.imdg.RemoteMapSourceAndSink" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "Creating and populating remote Hazelcast instance..."
check_map_content "Local map-1 contents:"
check_map_content "Remote map-2 contents:"

