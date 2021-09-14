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

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/hazelcast-connectors
mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.connectors.RemoteMapSourceAndSink" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "Creating and populating remote Hazelcast instance..."
check_map_content "Local map-1 contents:"
check_map_content "Remote map-2 contents:"

