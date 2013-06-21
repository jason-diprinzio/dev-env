#!/bin/bash

if [ -f install-files ]
then
    files=`cat install-files`
    for file in $files
    do
        echo "copying $file to /usr/local/bin"
        cp $file /usr/local/bin
    done
    exit 0
fi

echo "Cannot find install-files"
exit 1


