#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export AVRO_SOURCE=${CODE_SAMPLES_HOME}/jet/files/users

function check_text_in_log {
    EXPECTED_TEXT=$1
    echo "Checking log for '${EXPECTED_TEXT}'"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${OUTPUT_LOG_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -lt 1 ]; then   
        echo "Log '${EXPECTED_TEXT}' has not been found in output log.";
        exit 1
    fi
}

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/files

# It's necessary to run AvroSink first to create source data
mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.files.avro.AvroSink" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec

if [ ! -d ${AVRO_SOURCE} ]
then
    echo "Directory ${AVRO_SOURCE} should be created during code sample execution."
    exit 1
fi
if [ -z "$(ls -A ${AVRO_SOURCE})" ]
then
    echo "Directory ${AVRO_SOURCE} should not be empty."
    exit 1
fi

mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.files.avro.AvroSource" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
for ((i = 0; i < 100; i += 2)); do
    check_text_in_log "User$i - User{username='User$i', password='pass$i', age=$i, status=true}"
done
for ((i = 1; i < 100; i += 2)); do
    check_text_in_log "User$i - User{username='User$i', password='pass$i', age=$i, status=false}"
done


