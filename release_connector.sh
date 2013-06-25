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

. env.sh

if [ -z "${PLATFORM_BASE_DIR}" ]
then
    echo -n "error $0:"
    echo "Please set PLATFORM_BASE_DIR in env.sh"
    exit 1
fi

if [ -z "${CON_SRC_DIR}" ]
then
    echo -n "error $0:"
    echo "Please set CON_SRC_DIR in env.sh"
    exit 1
fi

CON_TYPE=$1
SRC_CON_TYPE=`echo ${CON_TYPE} | cut -d ':' -f 1`
SRC_CON_ZIP=`ls ${CON_SRC_DIR}/${SRC_CON_TYPE}/target/connector-*.zip`

if [ ! -f "${SRC_CON_ZIP}" ] ; then
    echo "Could not find ${CON_SRC_DIR}/${SRC_CON_TYPE}/target/connector-*.zip"
    exit 1
fi

conn_info=`echo ${SRC_CON_ZIP} | connector-info.pl`

CON_VERSION=`echo ${conn_info} | awk '{print $1}'`
DST_CON_TYPE=`echo ${conn_info} | awk '{print $2}'`
CONN_FILE_NAME=connector-${DST_CON_TYPE}-${CON_VERSION}-car.zip

#TODO verify
result=$?

#Decide where to install
if [ "$2" == "--local-only" ]
then
    #Install into a container
    echo "Installing connector ${DST_CON_TYPE}" ${SRC_CON_ZIP} "to" connector/${DST_CON_TYPE}/${CONN_FILE_NAME}

    mkdir -p connector/${DST_CON_TYPE}
    cp ${SRC_CON_ZIP} connector/${DST_CON_TYPE}/${CONN_FILE_NAME}
else
    CON_INSTALL_DIR=${PLATFORM_BASE_DIR}/connector/${DST_CON_TYPE} 
    mkdir -p ${CON_INSTALL_DIR}

    CON_UPDATE_DIR=${PLATFORM_BASE_DIR}/updates/connectors/${DST_CON_TYPE}
    mkdir -p ${CON_UPDATE_DIR}

    #Install into platform
    DEST_FILE=${CON_UPDATE_DIR}/${CONN_FILE_NAME}

    echo "Installing connector ${DST_CON_TYPE}" ${SRC_CON_ZIP} "to" ${DEST_FILE}
    cp ${SRC_CON_ZIP} ${DEST_FILE}
    echo "Creating MD5 digest for ${DEST_FILE}"
    md5file.sh ${DEST_FILE}

    cp ${DEST_FILE} ${CON_UPDATE_DIR}
    cp ${DEST_FILE}.MD5 ${CON_UPDATE_DIR}

    url="http://localhost:8081/update/ConnectorDownload/${CON_VERSION}?connectorType=${DST_CON_TYPE}"
    echo $url
    curl -i -uadmin@boomi.com:boomi $url 
    echo 
fi 

