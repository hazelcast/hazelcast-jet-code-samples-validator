#!/bin/bash

export SCRIPT_WORKSPACE=$1
export JET_REPO=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log

function check_text_in_log {
    EXPECTED_TEXT=$1
    echo "Checking log for '${EXPECTED_TEXT}'"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${OUTPUT_LOG_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -lt 1 ]; then   
        echo "Log '${EXPECTED_TEXT}' has not been found in ${OUTPUT_LOG_FILE}.";
        exit 1
    fi
}

function check_text_not_in_log {
    CHECKED_TEXT=$1
    echo "Checking log does not include '${CHECKED_TEXT}'"
    CHECKED_TEXT_COUNT=$(grep "${CHECKED_TEXT}" ${OUTPUT_LOG_FILE} | wc -l)
    if [ ${CHECKED_TEXT_COUNT} -gt 0 ]; then   
        echo "Log '${CHECKED_TEXT}' has been found in ${OUTPUT_LOG_FILE} even before job was executed.";
        exit 1
    fi
}

function kill_process {
    TO_KILL=$1
    echo "Searching for PID of process '${TO_KILL}'"
    jps -m
    PID_TO_KILL=$(jps | grep "${TO_KILL}" | awk '{print $1}')
    echo "Killing process '${PID_TO_KILL}'"
    kill -9 ${PID_TO_KILL}
}

cd ${JET_REPO}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${JET_REPO}/examples/spring-boot
mvn "-Dexec.args=-classpath %classpath com.hazelcast.jet.examples.spring.SpringBootSample" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE} &
sleep 60

####################################################
### verify code sample output before running job ###
####################################################
check_text_in_log "Starting SpringBootSample on"
check_text_in_log "Members {size:1, ver:1} \["
check_text_not_in_log ": foo"
check_text_not_in_log ": bar"

##################
### submit job ###
##################
curl http://localhost:8080/submitJob

#################################
### verify code sample output ###
#################################
check_text_in_log ": foo"
check_text_in_log ": bar"

# kill Jet
kill_process "SpringBootSample"
sleep 5
echo "Finished OK"
