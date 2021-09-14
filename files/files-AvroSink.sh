#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export AVRO_SINK=${CODE_SAMPLES_HOME}/jet/files/users

function check_text_in_avro_file {
    EXPECTED_TEXT=$1
    echo "Checking log for '${EXPECTED_TEXT}'"
    AVRO_SINK_FILE=${AVRO_SINK}/0
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${AVRO_SINK_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -lt 1 ]; then   
        echo "Log '${EXPECTED_TEXT}' has not been found in avro sink file.";
        exit 1
    fi
}

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/files
mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.files.avro.AvroSink" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
if [ ! -d ${AVRO_SINK} ]
then
    echo "Directory ${AVRO_SINK} should be created during code sample execution."
    exit 1
fi
if [ -z "$(ls -A ${AVRO_SINK})" ]
then
    echo "Directory ${AVRO_SINK} should not be empty."
    exit 1
fi

for i in {0..99}; do
    check_text_in_avro_file "User$i"
    check_text_in_avro_file "pass$i"
done


