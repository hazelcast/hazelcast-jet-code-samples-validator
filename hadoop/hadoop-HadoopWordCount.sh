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

function verify_word_count {
    CHECKED_WORD=$1
    EXPECTED_COUNT=$2
    CHECKED_DIRECTORY=$3
    echo "Checking log for word '${CHECKED_WORD}'"
    CHECKED_WORD_COUNT=$(grep "^${CHECKED_WORD}[[:space:]]" -R ${CHECKED_DIRECTORY} | awk '{ print $2 }')
    if [ ${CHECKED_WORD_COUNT} -ne ${EXPECTED_COUNT} ]; then   
        echo "Log includes incorrect number of word '${EXPECTED_TEXT}'. Expected: ${EXPECTED_COUNT}, but was: ${CHECKED_WORD_COUNT}.";
        exit 1
    fi
}

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/hadoop
mvn "-Dexec.args=-classpath ${CODE_SAMPLES_HOME}/jet/wordcount/target/classes/:%classpath com.hazelcast.samples.jet.hadoop.HadoopWordCount" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
check_text_in_log "Counting words from ${CODE_SAMPLES_HOME}/jet/wordcount/target/classes/books"
check_text_in_log "Total input files to process : 20"
check_text_in_log "Done in [0-9]* milliseconds."
check_text_in_log "Output written to hadoop-word-count"

HADOOP_WORD_COUNT_DIR=${CODE_SAMPLES_HOME}/jet/hadoop/hadoop-word-count
if [ ! -d ${HADOOP_WORD_COUNT_DIR} ]
then
    echo "Directory ${HADOOP_WORD_COUNT_DIR} should be created during code sample execution."
    exit 1
fi

if [ -z "$(ls -A ${HADOOP_WORD_COUNT_DIR})" ]
then
    echo "Directory ${HADOOP_WORD_COUNT_DIR} should not be empty."
    exit 1
fi

verify_word_count "the" 121242 ${HADOOP_WORD_COUNT_DIR}
verify_word_count "have" 13614 ${HADOOP_WORD_COUNT_DIR}
verify_word_count "some" 4197 ${HADOOP_WORD_COUNT_DIR}

