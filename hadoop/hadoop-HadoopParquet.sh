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

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/hadoop
mvn "-Dexec.args=-classpath %classpath com.hazelcast.samples.jet.hadoop.parquet.HadoopParquet" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
for ((i = 0; i < 100; i += 2)); do
    check_text_in_log "{\"name\": \"name$i\", \"password\": \"pass$i\", \"age\": $i, \"status\": true}"
done

export HDFS_INPUT_DIR=${CODE_SAMPLES_HOME}/jet/hadoop/hdfs-parquet-input
export HDFS_OUTPUT_DIR=${CODE_SAMPLES_HOME}/jet/hadoop/hdfs-parquet-output

if [ ! -d ${HDFS_INPUT_DIR} ]
then
    echo "Directory ${HDFS_INPUT_DIR} should be created during code sample execution."
    exit 1
fi

if [ -z "$(ls -A ${HDFS_INPUT_DIR})" ]
then
    echo "Directory ${HDFS_INPUT_DIR} should not be empty."
    exit 1
fi

if [ ! -d ${HDFS_OUTPUT_DIR} ]
then
    echo "Directory ${HDFS_OUTPUT_DIR} should be created during code sample execution."
    exit 1
fi

if [ -z "$(ls -A ${HDFS_OUTPUT_DIR})" ]
then
    echo "Directory ${HDFS_OUTPUT_DIR} should not be empty."
    exit 1
fi
