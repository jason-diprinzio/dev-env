#!/bin/bash
#

function usage() {
    echo "`basename $0` [option]"
    echo "  --dev    build only 1 user-agent, skip tests and deploy in dev mode."
    echo "  --gwt20  deploys build for GWT 2.0 using the older symlinking style for the webapp. Requires --dev"
    exit 1
}

DEPLOY_GWT_2_0=0
DEV_BUILD=0

while getopts ":h-:" opt
do
    case "${opt}" in
        -)
            case "${OPTARG}" in
                gwt20)
                    echo "Using GWT 2.0 style symlinking"
                    DEPLOY_GWT_2_0=1
                    ;;
                dev)
                    echo "Deploying development build"
                    DEV_BUILD=1
                    ;;
                help)
                    usage
                    ;;
                *)
                    echo "unknown option --${OPTARG}"
                    usage
                    ;;
            esac;;
        h)
            usage
            ;;
    esac
done
