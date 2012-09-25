#!/bin/bash

function usage() {
    echo `basename $0`  " <project:conn-name> [--local-only]"
}

if [ "$1" == "-h" ]
then
    usage
    exit 0
fi

if [ -z $1 ]
then
    usage
    exit 1
fi

if [ -z ${UPDATE_DIR} ]
then
    UPDATE_DIR=/var/lib/tomcat6/updates
fi

if [ -z ${CON_SRC_DIR} ]
then
    CON_SRC_DIR=/home/jason/Projects/connectors
fi

CON_TYPE=$1
SRC_CON_TYPE=`echo ${CON_TYPE} | cut -d ':' -f 1`
SRC_CON_ZIP=`ls ${CON_SRC_DIR}/${SRC_CON_TYPE}/target/connector-*.zip`

if [ ! -f "${SRC_CON_ZIP}" ] ; then
    echo "Could not find ${CON_SRC_DIR}/${SRC_CON_TYPE}/target/connector-*.zip"
    exit 1
fi

conn_info=`echo ${SRC_CON_ZIP} | ~/bin/connector-info.pl`

CON_VERSION=`echo ${conn_info} | awk '{print $1}'`
DST_CON_TYPE=`echo ${conn_info} | awk '{print $2}'`

#TODO verify
result=$?

#Decide where to install
if [ "$2" == "--local-only" ]
then
    #Install into a container
    echo "Installing connector ${DST_CON_TYPE}" ${SRC_CON_ZIP} "to" connector/${DST_CON_TYPE}/connector-*.zip
    mkdir -p connector/${DST_CON_TYPE}
    cp ${SRC_CON_ZIP} connector/${DST_CON_TYPE}/connector-*.zip
else
    #Install into platform
    CON_UPDATE_DIR=${UPDATE_DIR}/connectors/${DST_CON_TYPE}
    mkdir -p ${CON_UPDATE_DIR}
    DEST_FILE=${CON_UPDATE_DIR}/connector-${DST_CON_TYPE}-${CON_VERSION}-car.zip

    echo "Installing connector ${DST_CON_TYPE}" ${SRC_CON_ZIP} "to" ${DEST_FILE}
    cp ${SRC_CON_ZIP} ${DEST_FILE}
    ~/bin/md5file.sh ${DEST_FILE}

    url="http://localhost:8081/update/ConnectorDownload/${CON_VERSION}?connectorType=${DST_CON_TYPE}"
    echo $url
    curl -i -uadmin@boomi.com:boomi $url 
    echo 
fi 

