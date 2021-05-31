#!/bin/bash

export SCRIPT_WORKSPACE=$1
export CODE_SAMPLES_HOME=$2

export OUTPUT_LOG_FILE=${SCRIPT_WORKSPACE}/output.log
export SOURCE_DIRECTORY=${SCRIPT_WORKSPACE}/source
export SINK_DIRECTORY=${SCRIPT_WORKSPACE}/source

function check_text_in_sink {
    EXPECTED_TEXT=$1
    echo "Checking log for '${EXPECTED_TEXT}'"
    SINK_FILE=${SINK_DIRECTORY}/0
    EXPECTED_TEXT_COUNT=$(grep "${EXPECTED_TEXT}" ${SINK_FILE} | wc -l)
    if [ ${EXPECTED_TEXT_COUNT} -lt 1 ]; then   
        echo "Log '${EXPECTED_TEXT}' has not been found in sink file.";
        exit 1
    fi
}

cd ${CODE_SAMPLES_HOME}
mvn clean install -U -B -Dmaven.test.failure.ignore=true -DskipTests

# prepare source directory
mkdir ${SOURCE_DIRECTORY}
cp ${CODE_SAMPLES_HOME}/jet/files/data/access_log.processed ${SOURCE_DIRECTORY}

###########################
### execute code sample ###
###########################
cd ${CODE_SAMPLES_HOME}/jet/files
mvn "-Dexec.args=-classpath %classpath com.hazelcast.samples.jet.files.AccessLogAnalyzer ${SOURCE_DIRECTORY} ${SINK_DIRECTORY}" -Dexec.executable=java org.codehaus.mojo:exec-maven-plugin:1.6.0:exec | tee ${OUTPUT_LOG_FILE}

#################################
### verify code sample output ###
#################################
if [ ! -d ${SINK_DIRECTORY} ]
then
    echo "Directory ${SINK_DIRECTORY} should be created during code sample execution."
    exit 1
fi
if [ -z "$(ls -A ${SINK_DIRECTORY})" ]
then
    echo "Directory ${SINK_DIRECTORY} should not be empty."
    exit 1
fi

check_text_in_sink "/img/icons/ssi.png=20"
check_text_in_sink "/files/private/=2"
check_text_in_sink "/test/python/=11"
check_text_in_sink "/img/bullet.gif=20"
check_text_in_sink "/img/apps/poa-box.gif=20"
check_text_in_sink "/img/apps/=80"
check_text_in_sink "/img/icons/fastcgi.png=20"
check_text_in_sink "/img/apps/pcp-box.gif=20"
check_text_in_sink "/test/python/test.html=6"
check_text_in_sink "/adminer.php=12"
check_text_in_sink "/test/python/test.py=5"
check_text_in_sink "/files/private/admin/=4"
check_text_in_sink "/img/panel-logo.png=20"
check_text_in_sink "/css/style.css=62"
check_text_in_sink "/test/perl/test.pl=11"
check_text_in_sink "/files/=2"
check_text_in_sink "/img/=293"
check_text_in_sink "/css/=62"
check_text_in_sink "/=232"
check_text_in_sink "/__settings0.php=2"
check_text_in_sink "/favicon.ico=24"
check_text_in_sink "/img/p-box.png=10"
check_text_in_sink "/test/fcgi/test.html=10"
check_text_in_sink "/test/ssi/test.shtml=10"
check_text_in_sink "/img/th.png=3"
check_text_in_sink "/test/=95"
check_text_in_sink "/test/perl/=21"
check_text_in_sink "/img/parallels-logo.png=20"
check_text_in_sink "/test/ssi/=20"
check_text_in_sink "/__extensions0.php=1"
check_text_in_sink "/test/fcgi/=20"
check_text_in_sink "/img/apps/pdfwl-box.gif=20"
check_text_in_sink "/img/icons/=100"
check_text_in_sink "/img/icons/php.png=20"
check_text_in_sink "/img/apps/pd-box.gif=20"
check_text_in_sink "/test/ssi/test.html=10"
check_text_in_sink "/test/php/test.html=10"
check_text_in_sink "/img/icons/perl.png=20"
check_text_in_sink "/img/icons/python.png=20"
check_text_in_sink "/test/php/test.php=13"
check_text_in_sink "/test/perl/test.html=10"
check_text_in_sink "/img/top-bottom.png=20"
check_text_in_sink "/img/globe.png=20"
check_text_in_sink "/test/php/=23"
check_text_in_sink "/index.html=4"
check_text_in_sink "/test/fcgi/test.fcgi=10"

