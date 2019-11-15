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
cd ${JET_REPO}/examples/hadoop
mvn "-Dexec.args=-classpath %classpath com.hazelcast.jet.examples.hadoop.avro.HadoopAvro" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
for ((i = 0; i < 100; i += 2)); do
    check_text_in_log "avro.User{username='name$i', password='pass$i', age=$i, status=true}"
done

if [ ! -d ${JET_REPO}/examples/hadoop/hdfs-avro-input ]
then
    echo "Directory ${JET_REPO}/examples/hadoop/hdfs-avro-input should be created during code sample execution."
    exit 1
fi

if [ ! -d ${JET_REPO}/examples/hadoop/hdfs-avro-output ]
then
    echo "Directory ${JET_REPO}/examples/hadoop/hdfs-avro-output should be created during code sample execution."
    exit 1
fi
