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
cd ${CODE_SAMPLES_HOME}/jet/kafka
mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.kafka.KafkaSource" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec 2>&1 | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
echo "Searching for job ID ..."
JOB_ID=$(sed -n 's:.* Execution plan for jobId=\(.*\), jobName=.*:\1:p' ${OUTPUT_LOG_FILE})
if [ "x${JOB_ID}" == "x" ]; then   
    echo "'Execution plan for jobId' has not been found in output log.";
    exit 1
fi
echo "job ID is ${JOB_ID}"

echo "Searching for job executionId ..."
JOB_EXECUTION_ID=$(sed -n 's:.*, executionId=\(.*\) initialized.*:\1:p' ${OUTPUT_LOG_FILE})
if [ "x${JOB_EXECUTION_ID}" == "x" ]; then   
    echo "executionId for job has not been found in output log.";
    exit 1
fi
echo "job executionId is ${JOB_EXECUTION_ID}"

echo "Checking whether job finished as expected ..."
EXPECTED_JOB_FINISH_LOG_COUNT=$(grep "Execution of job '${JOB_ID}', execution ${JOB_EXECUTION_ID} .*, reason=java.util.concurrent.CancellationException" ${OUTPUT_LOG_FILE} | wc -l)
if [ ${EXPECTED_JOB_FINISH_LOG_COUNT} -lt 1 ]; then   
    echo "executionId for job has not been found in output log.";
    exit 1
fi

check_text_in_log "\[ZooKeeperClient Kafka server\] Connected"
check_text_in_log "\[KafkaServer id=0\] started"
check_text_in_log "Filling Topics"
check_text_in_log "Published 1000000 messages to topic t1"
check_text_in_log "Published 1000000 messages to topic t2"
check_text_in_log "Received 2000000 entries in [0-9]* milliseconds"

