#!/bin/bash

START=0
KEEP=0
CLOUD=0
HTTP=0
PROXY=0
CONNS=

while getopts ":h-:" opt; do
    case "${opt}" in
        -)
            case "${OPTARG}" in
                start)
                    START=1
                    ;;
                keep)
                    KEEP=1
                    ;;
                cloud)
                    CLOUD=1
                    ;;
                http)
                    HTTP=1
                    ;;
                proxy)
                    PROXY=1
                    ;;
                conn=*)
                    CONNS="${CONNS} ${OPTARG#*=}"
                    ;;
                *)
                    echo "unknown option --${OPTARG}"
                    exit 1
                    ;;
            esac;;
        h)
            echo "usage: `basename $0` [--start|--keep|--cloud|--http|--proxy|--conn={connector}]"
            exit 1
            ;;
    esac
done

# ensure that all atoms are stopped!
if [ ${START} -eq 1 ] ; then
    if [ -f bin/atom ]
    then
        bin/atom stop
    else
        ~/bin/cloudctl stop
    fi
fi

install_zip()
{
    ZIP_TYPE="$1"
    shift
    for ZIP_FILE in "$@"; do
        echo "Installing ${ZIP_TYPE} '${ZIP_FILE}'"
        unzip -qo "${ZIP_FILE}"
    done
}

rm -f bin/*.log
rm -f logs/*.log
rm -rf work/*
rm -rf tmp/*

if [ -z "${ATOM_SRC_DIR}" ] ; then
    ATOM_SRC_DIR="/home/jason/Projects/atom"
fi

if [ -d "${ATOM_SRC_DIR}" ] ; then

    if [ ${KEEP} -eq 1  ] ; then
        echo "Keeping current dists"
    else
        rm -rf lib/*

        install_zip "base" ${ATOM_SRC_DIR}/dist/target/container-dist-*.zip
        install_zip "groovy" ${ATOM_SRC_DIR}/shared-server/groovy-dist/target/container-groovy-dist-*.zip
        install_zip "embeddb" ${ATOM_SRC_DIR}/shared-server/embedded-db-dist/target/container-embedded-db-dist-*.zip
    fi

    if [ ${CLOUD} -eq 1 ] ; then
        install_zip "cloud" ${ATOM_SRC_DIR}/cloudlet-dist/target/container-cloudlet-dist-*.zip

        if [ -a "bin/procrunner.policy.jta" ] ; then
            echo "Reinstalling bin/procrunner.policy.jta"
            cp "bin/procrunner.policy.jta" "bin/procrunner.policy"
        fi
    fi

    if [ ${HTTP} -eq 1 ] ; then
        install_zip "http" ${ATOM_SRC_DIR}/shared-server/http-dist/target/container-shared-server-http-dist-*.zip
        install_zip "extsec" ${ATOM_SRC_DIR}/shared-server/extended-security-dist/target/container-extended-security-dist-*.zip
    fi

    if [ ${PROXY} -eq 1 ] ; then
        install_zip "proxy bridge" ${ATOM_SRC_DIR}/proxy/bridge-dist/target/container-proxy-bridge-dist-*.zip
        install_zip "proxy client" ${ATOM_SRC_DIR}/proxy/client-dist/target/container-proxy-client-dist-*.zip
    fi
fi

if [ -z "${CON_SRC_DIR}" ] ; then
    CON_SRC_DIR="/home/jason/Projects/connectors"
fi

if [ -d "${CON_SRC_DIR}" ] ; then

    if [ -n "${CONNS}" ] ; then
        read -rd '' CONNS <<< "$CONNS"
        for CONN in $CONNS
        do
            ~/bin/release_connector.sh  "${CONN}" --local-only
        done
    fi
fi

if [ ${START} -eq 1 ] ; then
    if [ -f bin/atom ]
    then
        bin/atom start
    else
        ~/bin/cloudctl start
    fi
fi

