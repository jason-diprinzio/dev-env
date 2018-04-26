#!/bin/bash

. get_project.sh

get_project

if [ $? != 0 ]
then
    echo "Could not get project name (get_project.sh)"
    exit 127
fi

if [ "${project_name}" != "BoomiIntegrationPlatform" ]
then
    echo "Not a working copy of the platform"
    exit 127
fi

. env.sh
. build_args.sh

function revert() {
    # this script should be idempotent
    # so it won't matter if it's called
    # unnecessarily
    fix-platform-build.pl ci
    exit 1
}

trap revert SIGHUP SIGINT SIGTERM

echo "Enter root/sudo password."
sudo echo 

if [ $? -ne 0 ]
then
    echo "Could not authenticate for sudo."
    exit 1
fi

mvnopts+="-DskipTests -Pgwt-dev "

if [ 1 -eq ${DEV_BUILD} ]
then
    fix-platform-build.pl co
fi

rm -rf gwt/ui/war/WEB-INF/classes
rm -rf gwt/ui/war/WEB-INF/lib
rm -rf gwt/ui/war/AtomSphere

mvn ${mvnopts} -pl model,common,gwt/model clean install
buildresult=$?

if [ $buildresult -ne 0 ]
then
    fix-platform-build.pl ci
    exit $buildresult
fi

# shit sandwich time...eat up
mvn ${mvnopts} -rf gwt/ui clean install
buildresult=$?

fix-platform-build.pl ci

if [ $buildresult -ne 0 ]
then
    exit $buildresult
fi

sudo deployplat $@

./liquibutil.sh update default

if [ $? -eq 0 ]
then
    sudo service jetty stop
    sudo rm /var/log/boomi/jetty/*.log
    sudo rm /var/log/boomi/jetty/app/*
    sudo rm /var/log/boomi/jetty/request/*
    sudo service jetty start
fi

