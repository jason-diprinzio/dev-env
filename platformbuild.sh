#!/bin/bash

. get_project.sh

get_project

if [ $? != 0 ]
then
    echo "Could not execute get_project script (get_project.sh)"
    exit 127
fi

if [ "${project_name}" != "BoomiIntegrationPlatform" ]
then
    echo "Not a working copy of the platform"
    exit 127
fi

. env.sh

function revert() {
    # this script should be idempotent
    # so it won't matter if it's called
    # unnecessarily
    fix-platform-build.pl ci
    exit 1
}

trap revert SIGHUP SIGINT SIGTERM

function usage() {
    echo "`basename $0` [option]"
    echo "  --gwt20  deploys build for GWT 2.0 using the older symlinking style for the webapp."
    echo "  --dev    build only 1 user-agent and skip tests."
    exit 1
}

DEPLOY_GWT_2_0=
DEV_BUILD=0

while getopts ":h-:" opt
do
    case "${opt}" in
        -)
            case "${OPTARG}" in
                gwt20)
                    DEPLOY_GWT_2_0=--gwt
                    ;;
                dev)
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

echo "Enter root/sudo password."
sudo echo 

if [ $? -ne 0 ]
then
    echo "Could not authenticate for sudo."
    exit 1
fi

if [ ${DEV_BUILD} -eq 1 ]
then
    fix-platform-build.pl co
    mvnopts="-DskipTests"
fi

rm -rf gwt/ui/war/WEB-INF/classes
rm -rf gwt/ui/war/WEB-INF/lib
rm -rf gwt/ui/war/AtomSphere

cmd="time mvn ${mvnopts} clean install"

eval $cmd
buildresult=$?

fix-platform-build.pl ci

if [ $buildresult -ne 0 ]
then
    exit $buildresult
fi

sudo deployplat ${DEPLOY_GWT_2_0}

if [ $? -eq 0 ]
then
    sudo rm ${PLATFORM_BASE_DIR}/logs/*
    # TODO make this configurable
    if [ -f /etc/init.d/tomcat6 ]
    then
        sudo /etc/init.d/tomcat6 restart
    fi
fi

