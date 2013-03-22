#!/bin/bash

. ~/bin/get_project.sh

get_project
if [ $? != 0 ]
then
    exit 127
fi

if [ "${project_name}" != "BoomiIntegrationPlatform" ]
then
    echo "Not a working copy of the platform"
    exit 127
fi

echo "Enter root/sudo password."
sudo echo 

if [ $? -ne 0 ]
then
    echo "Could not authenticate for sudo."
    exit 1
fi

if [ "$1" == "--gwt" ]
then
    ~/bin/fix-platform-build.pl co
    mvnopts="-DskipTests"
fi

rm -rf gwt/ui/war/WEB-INF/classes
rm -rf gwt/ui/war/WEB-INF/lib
rm -rf gwt/ui/war/AtomSphere

cmd="time mvn ${mvnopts} clean install"

eval $cmd
buildresult=$?

~/bin/fix-platform-build.pl ci

if [ $buildresult -ne 0 ]
then
    exit 2
fi

sudo -E ~/bin/deployplat $@

sudo rm /var/lib/tomcat6/logs/*
sudo /etc/init.d/tomcat6 restart

