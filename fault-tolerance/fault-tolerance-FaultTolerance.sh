#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export BEFORE_RESTART_LOG_FILE=${SCRIPT_WORKSPACE}/before_restart_output.log
export AFTER_RESTART_LOG_FILE=${SCRIPT_WORKSPACE}/after_restart_output.log

function check_text_in_log {
    EXPECTED_TEXT=$1
    LOG_FILE=$2
    echo "Checking log for '${EXPECTED_TEXT}'"
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${LOG_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -lt 1 ]; then   
        echo "Log '${EXPECTED_TEXT}' has not been found in ${LOG_FILE}.";
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

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/fault-tolerance
mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.faulttolerance.FaultTolerance" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE} &
sleep 60

# kill Jet
kill_process "FaultTolerance"
sleep 5

#################################
### verify code sample output ###
#################################
check_text_in_log "Member shut down, the job will now restart and you can inspect the output again." $OUTPUT_LOG_FILE

HEAD_DELIMITER=$(awk '/Member shut down, the job will now restart and you can inspect the output again./{ print NR; exit }' $OUTPUT_LOG_FILE)
TAIL_DELIMITER=$(($(wc -l $OUTPUT_LOG_FILE | awk '{ print $1 }') - $HEAD_DELIMITER))

head -n $HEAD_DELIMITER $OUTPUT_LOG_FILE >> $BEFORE_RESTART_LOG_FILE
tail -n $TAIL_DELIMITER $OUTPUT_LOG_FILE >> $AFTER_RESTART_LOG_FILE

check_text_in_log "Starting price updater. You should start seeing the output after 5 seconds" $BEFORE_RESTART_LOG_FILE
check_text_in_log "After 20 seconds, one of the nodes will be shut down." $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='GOOG', value='1', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='AMZN', value='1', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='TSLA', value='1', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='EBAY', value='1', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='TSLA', value='1', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='MSFT', value='1', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='GOOG', value='2', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='AMZN', value='2', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='TSLA', value='2', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='EBAY', value='2', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='TSLA', value='2', isEarly=false}" $BEFORE_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='MSFT', value='2', isEarly=false}" $BEFORE_RESTART_LOG_FILE

check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='GOOG', value='1', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='AMZN', value='1', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='TSLA', value='1', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='EBAY', value='1', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='TSLA', value='1', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='MSFT', value='1', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='GOOG', value='2', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='AMZN', value='2', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='TSLA', value='2', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='EBAY', value='2', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='TSLA', value='2', isEarly=false}" $AFTER_RESTART_LOG_FILE
check_text_in_log "KeyedWindowResult{start=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, end=[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}, key='MSFT', value='2', isEarly=false}" $AFTER_RESTART_LOG_FILE

