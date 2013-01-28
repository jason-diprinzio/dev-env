#!/bin/bash

echo "Enter root/sudo password."
sudo echo 

if [ $? -ne 0 ]
then
    echo "Could not authenticate for sudo."
    exit 1
fi

~/bin/fix-platform-build.pl co

time mvn -DskipTests clean install

buildresult=$?

~/bin/fix-platform-build.pl ci

if [ $buildresult -ne 0 ]
then
    exit 2
fi

sudo -E ~/bin/deployplat $@

sudo /etc/init.d/tomcat6 restart

