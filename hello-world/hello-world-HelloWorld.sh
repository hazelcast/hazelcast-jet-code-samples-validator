#!/bin/bash

export SCRIPT_WORKSPACE=$1
export JET_REPO=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log

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
HZ_VERSION=$(grep "<version>" ${JET_REPO}/examples/hello-world/pom.xml | cut -d'>' -f 2 | cut -d'<' -f 1)
cd ${SCRIPT_WORKSPACE}
unzip -q ${JET_REPO}/hazelcast-jet-distribution/target/hazelcast-jet-${HZ_VERSION}.zip
cd hazelcast-jet-*/bin
# start Jet
./jet-start &
sleep 15

# submit code sample
./jet submit ${JET_REPO}/examples/hello-world/target/hazelcast-jet-examples-hello-world-${HZ_VERSION}.jar > ${OUTPUT_LOG_FILE} &
sleep 20

# kill Jet
kill_process "JetCommandLine"
kill_process "JetMemberStarter"
sleep 5

#################################
### verify code sample output ###
#################################
INITIAL_TEXT_COUNT=$(grep "Top 10 random numbers in the latest window:" ${OUTPUT_LOG_FILE} | wc -l)
if [ ${INITIAL_TEXT_COUNT} -lt 1 ]; then   
    echo "Log 'Top 10 random numbers in the latest window:' has not been found in output log.";
    exit 1
fi

MINIMAL_OCCURS=$(($INITIAL_TEXT_COUNT - 2))
for i in {1..10}; do
    EXPECTED_LINE_COUNT=$(grep "$i\. [0-9,]*$" ${OUTPUT_LOG_FILE} | wc -l)
    echo "Checking output for '$i\.' result...";
    if [ ${EXPECTED_LINE_COUNT} -lt 1 ]; then   
        echo "Log with results on position '$i.' has not been found in output log.";
        exit 1
    fi
    if [ ${EXPECTED_LINE_COUNT} -lt ${MINIMAL_OCCURS} ]; then   
        echo "Log with results on position '$i.' should occur in log more times than it occured.";
        exit 1
    fi    
done


