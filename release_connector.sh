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

if [ -z "${PLATFORM_BOOMI_DIR}" ]
then
    echo -n "error $0:"
    echo "Please set PLATFORM_BOOMI_DIR in env.sh"
    exit 1
fi

if [ -z "${CON_SRC_DIR}" ]
then
    echo -n "error $0:"
    echo "Please set CON_SRC_DIR in env.sh"
    exit 1
fi

CON_TYPE="$1"
SRC_CON_TYPE=`echo "${CON_TYPE}" | cut -d ':' -f 1`
SRC_CON_ZIP=`ls ${CON_SRC_DIR}/${SRC_CON_TYPE}/target/connector-*.zip`

if [ ! -f "${SRC_CON_ZIP}" ] ; then
    echo "Could not find ${CON_SRC_DIR}/${SRC_CON_TYPE}/target/connector-*.zip"
    exit 1
fi

conn_info=`echo "${SRC_CON_ZIP}" | connector-info.pl`

CON_VERSION=`echo "${conn_info}" | awk '{print $1}'`
DST_CON_TYPE=`echo "${conn_info}" | awk '{print $2}'`
CONN_FILE_NAME=connector-"${DST_CON_TYPE}-${CON_VERSION}"-car.zip

#TODO verify
result=$?

#Decide where to install
if [ "$2" == "--local-only" ]
then
    #Install into a container
    echo "Installing connector ${DST_CON_TYPE} ${SRC_CON_ZIP} to connector/${DST_CON_TYPE}/${CONN_FILE_NAME}"

    mkdir -p connector/"${DST_CON_TYPE}"
    cp "${SRC_CON_ZIP}" connector/"${DST_CON_TYPE}/${CONN_FILE_NAME}"
else
    CON_INSTALL_DIR="${PLATFORM_CONNECTOR_DIR}/${DST_CON_TYPE}" 
    mkdir -p "${CON_INSTALL_DIR}"

    CON_UPDATE_DIR="${PLATFORM_CONNECTOR_DIR}/${DST_CON_TYPE}"

    #Install into platform
    DEST_FILE="${CON_UPDATE_DIR}/${CONN_FILE_NAME}" 
    echo "Installing connector ${DST_CON_TYPE} ${SRC_CON_ZIP} to ${DEST_FILE}"
    cp "${SRC_CON_ZIP}" "${DEST_FILE}"

    #checksum-mama-bitch
    echo "Creating MD5 digest for ${DEST_FILE}"
    md5file.sh "${DEST_FILE}"

    DESCRIPTOR="${CON_SRC_DIR}/${SRC_CON_TYPE}/target/classes/connector-descriptor.xml"
    if [ -f "${DESCRIPTOR}" ]
    then
        echo "Copying connector descriptor: ${DESCRIPTOR} to ${PLATFORM_CONN_DESC_DIR}"
        cp "${DESCRIPTOR}" "${PLATFORM_CONN_DESC_DIR}/config-${DST_CON_TYPE}.xml"
    fi

    #Update the version in the Platform.
    url="http://localhost:8081/update/ConnectorDownload/${CON_VERSION}?connectorType=${DST_CON_TYPE}"
    echo $url
    curl -i -uadmin@boomi.com:boomi $url 
    echo 
fi 

