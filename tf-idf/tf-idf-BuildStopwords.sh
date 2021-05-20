#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export GENERATED_FILE=${CODE_SAMPLES_HOME}/jet/tf-idf/stopwords.txt

function check_text_in_generated_file {
    EXPECTED_TEXT=$1
    echo "Checking log for '${EXPECTED_TEXT}'"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${GENERATED_FILE} | wc -l)
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
cd ${CODE_SAMPLES_HOME}/jet/tf-idf
mvn "-Dexec.args=-classpath %classpath com.hazelcast.samples.jet.tfidf.BuildStopwords" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
LOG_COUNT=$(wc -l ${GENERATED_FILE} | awk '{ print $1 }')
if [ ${LOG_COUNT} -ne 827 ]; then   
    echo "There is unexpected line count in generated file.";
    exit 1
fi
check_text_in_generated_file "000$"
check_text_in_generated_file "mississippi$"
check_text_in_generated_file "zip$"

