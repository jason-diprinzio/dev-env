#!/bin/bash

name=`grep "<name>Boomi Integration Platform</name>" pom.xml`

if [ $? != 0 ]
then
    echo "Not a working copy of the platform project."
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

sudo /etc/init.d/tomcat6 restart

