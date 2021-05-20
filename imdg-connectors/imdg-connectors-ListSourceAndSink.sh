#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/imdg-connectors
mvn "-Dexec.args=-classpath %classpath com.hazelcast.samples.jet.imdg.ListSourceAndSink" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
RESULT_LIST_ITEMS=$(grep "Result list items:" ${OUTPUT_LOG_FILE})

if [ "x${RESULT_LIST_ITEMS}" == "x" ]; then   
    echo "'Result list items:' has not been found in output log.";
    exit 1
fi

for i in {0..9}; do
    EXPECTED_ITEM=item$i
    echo "Checking log for item '${EXPECTED_ITEM}'"
    EXPECTED_ITEM_COUNT=$(grep $EXPECTED_ITEM <<< "$RESULT_LIST_ITEMS" | wc -l)
    if [ ${EXPECTED_ITEM_COUNT} -ne 1 ]; then   
        echo "Item '${EXPECTED_ITEM}' is missing in output log.";
        exit 1
    fi
done

