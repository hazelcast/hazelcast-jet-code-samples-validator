#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log

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

cd ${CODE_SAMPLES_HOME}/hazelcast/
echo "cd into ${CODE_SAMPLES_HOME}/hazelcast/, current directory is: $(pwd)"
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
HZ_VERSION=$(grep "<hazelcast.version>" ${CODE_SAMPLES_HOME}/pom.xml | cut -d'>' -f 2 | cut -d'<' -f 1)
CODE_SAMPLES_VERSION=$(grep "<version>" ${CODE_SAMPLES_HOME}/jet/hello-world/pom.xml | cut -d'>' -f 2 | cut -d'<' -f 1)

cd ${SCRIPT_WORKSPACE}
unzip -q ${CODE_SAMPLES_HOME}/hazelcast/hazelcast-distribution/target/hazelcast-${HZ_VERSION}.zip
cd ./hazelcast/hazelcast-*/bin
# start Hazelcast member
./hazelcast-start &
sleep 15

# submit code sample
./hazelcast submit ${CODE_SAMPLES_HOME}/jet/hello-world/target/jet-hello-world-${CODE_SAMPLES_VERSION}.jar > ${OUTPUT_LOG_FILE} &
sleep 20

# kill hazelcast member and hazelcast cli processes
kill_process "JetCommandLine" # TODO: This name will change to the HazelcastCommandLine soon.
kill_process "HazelcastMemberStarter"
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


