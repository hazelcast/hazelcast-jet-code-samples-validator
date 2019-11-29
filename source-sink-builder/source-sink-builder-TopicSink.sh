#!/bin/bash

export SCRIPT_WORKSPACE=$1
export JET_REPO=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export OUTPUT_THE_LOG_FILE=${SCRIPT_WORKSPACE}/output_the.log

cd ${JET_REPO}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${JET_REPO}/examples/source-sink-builder
mvn "-Dexec.args=-classpath %classpath com.hazelcast.jet.examples.sinkbuilder.TopicSink" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
grep "Line starts with \`The\`:" ${OUTPUT_LOG_FILE} | tee ${OUTPUT_THE_LOG_FILE}

EXPECTED_THE_LOG_COUNT=$(wc -l ${OUTPUT_THE_LOG_FILE} | awk '{ print $1 }')
if [ ${EXPECTED_THE_LOG_COUNT} -ne 4286 ]; then   
    echo "Number of line which starts with 'The' is not as expected. Expected: 4286 but was ${EXPECTED_THE_LOG_COUNT}";
    exit 1
fi

THE_LOG_COUNT=$(grep "Line starts with \`The\`: The " ${OUTPUT_THE_LOG_FILE} | wc -l)
if [ ${THE_LOG_COUNT} -ne ${EXPECTED_THE_LOG_COUNT} ]; then   
    echo "There is unexpected line in log which should start with 'The'.";
    exit 1
fi
