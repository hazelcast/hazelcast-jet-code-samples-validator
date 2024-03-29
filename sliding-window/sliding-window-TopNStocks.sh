#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export RISING_STOCKS_FILE=${SCRIPT_WORKSPACE}/rising_stocks.log
export FALLING_STOCKS_FILE=${SCRIPT_WORKSPACE}/falling_stocks.log

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/sliding-windows
mvn "-Dexec.args=-Dhazelcast.phone.home.enabled=false -classpath %classpath com.hazelcast.samples.jet.slidingwindow.TopNStocks" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

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

echo "Checking whether log contains info about rising stocks ..."
sed -n '/Top rising stocks:/{n;p;n;p;n;p;n;p;n;p}' ${OUTPUT_LOG_FILE} | tee ${RISING_STOCKS_FILE}
RISING_STOCKS_ALL_LINES=$(wc -l ${RISING_STOCKS_FILE} | awk '{ print $1 }')
RISING_STOCKS_NUMBER_LINES=$(grep ".* by [0-9,\.]*%$" ${RISING_STOCKS_FILE} | wc -l)
RISING_STOCKS_NAN_LINES=$(grep ".* by NaN%$" ${RISING_STOCKS_FILE} | wc -l)
if [ ${RISING_STOCKS_NUMBER_LINES} -lt 1 ]; then   
  echo "There is no line in rising stock which includes some number value.";
  exit 1
fi
RISING_STOCKS_VALID_LINES=$((${RISING_STOCKS_NUMBER_LINES}+${RISING_STOCKS_NAN_LINES}))
if [ ${RISING_STOCKS_VALID_LINES} -ne ${RISING_STOCKS_ALL_LINES} ]; then   
  echo "There is line in rising stock which is not correct.";
  exit 1
fi 

echo "Checking whether log contains info about falling stocks ..."
sed -n '/Top falling stocks:/{n;p;n;p;n;p;n;p;n;p}' ${OUTPUT_LOG_FILE} | tee ${FALLING_STOCKS_FILE}
FALLING_STOCKS_ALL_LINES=$(wc -l ${FALLING_STOCKS_FILE} | awk '{ print $1 }')
FALLING_STOCKS_LINES_WITH_NEGATIVES=$(grep ".* by -[0-9,\.]*%$" ${FALLING_STOCKS_FILE} | wc -l)
if [ ${FALLING_STOCKS_LINES_WITH_NEGATIVES} -lt 1 ]; then   
  echo "There is no line in falling stock which includes some number value.";
  exit 1
fi
FALLING_STOCKS_LINES_WITH_POSITIVE_ZEROS=$(grep ".* by 0.00%$" ${FALLING_STOCKS_FILE} | wc -l)
FALLING_STOCKS_NAN_LINES=$(grep ".* by NaN%$" ${FALLING_STOCKS_FILE} | wc -l)
FALLING_STOCKS_CORRECT_LINES=$((${FALLING_STOCKS_LINES_WITH_NEGATIVES}+${FALLING_STOCKS_LINES_WITH_POSITIVE_ZEROS}+${FALLING_STOCKS_NAN_LINES}))
if [ ${FALLING_STOCKS_ALL_LINES} -ne ${FALLING_STOCKS_CORRECT_LINES} ]; then   
  echo "There is line in falling stock which is not correct.";
  exit 1
fi
FALLING_STOCKS_LINES_WITH_NEGATIVE_ZEROS=$(grep ".* by -0.00%$" ${FALLING_STOCKS_FILE} | wc -l)
FALLING_STOCKS_LINES_WITH_ZEROS=$((${FALLING_STOCKS_LINES_WITH_NEGATIVE_ZEROS}+${FALLING_STOCKS_LINES_WITH_POSITIVE_ZEROS}))
if [ ${FALLING_STOCKS_LINES_WITH_ZEROS} -eq ${FALLING_STOCKS_ALL_LINES} ]; then   
  echo "There is no line in falling stock which includes negative value.";
  exit 1
fi
