#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export OUTPUT_THE_LOG_FILE=${SCRIPT_WORKSPACE}/output_the.log

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/source-sink-builder
mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.sinkbuilder.TopicSink" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
grep "Line starts with \`The\`:" ${OUTPUT_LOG_FILE} | tee ${OUTPUT_THE_LOG_FILE}

EXPECTED_THE_LOG_COUNT=$(wc -l ${OUTPUT_THE_LOG_FILE} | awk '{ print $1 }')
if [ ${EXPECTED_THE_LOG_COUNT} -ne 2143 ]; then   
    echo "Number of line which starts with 'The' is not as expected. Expected: 2143 but was ${EXPECTED_THE_LOG_COUNT}";
    exit 1
fi

THE_LOG_COUNT=$(grep "Line starts with \`The\`: The " ${OUTPUT_THE_LOG_FILE} | wc -l)
if [ ${THE_LOG_COUNT} -ne ${EXPECTED_THE_LOG_COUNT} ]; then   
    echo "There is unexpected line in log which should start with 'The'.";
    exit 1
fi
