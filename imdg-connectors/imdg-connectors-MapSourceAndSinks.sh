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
cd ${JET_REPO}/examples/imdg-connectors
mvn "-Dexec.args=-classpath %classpath com.hazelcast.jet.examples.imdg.MapSourceAndSinks" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "\-\-\-\-\-\-\-\-\-\-Map Source and Sink \-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-"
check_text_in_log "\-\-\-\-\-\-\-\-\-\-\-\-\-\-Map with Merging\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-"
check_text_in_log "\-\-\-\-\-\-\-\-\-\-\-\-Map with Updating \-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-"
check_text_in_log "\-\-\-\-\-\-\-\-\-\-Map with EntryProcessor \-\-\-\-\-\-\-\-\-\-\-\-"
check_text_in_log "sum \- 45"

for item in {0..9}; do
    check_text_in_log "$item \- $item"
    check_text_in_log "$item \- $(($item+5))"
    if [ $(($item % 2)) -eq 0 ];
    then
        check_text_in_log "$item \- $item\-even"
    else
        check_text_in_log "$item \- $item\-odd"
    fi
done

