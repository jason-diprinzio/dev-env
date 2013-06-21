#!/bin/bash

if [ -f install-files ]
then
    files=`cat install-files`
    pushd /usr/local/bin
    for file in $files
    do
        rm $file
    done 
    popd
    exit 0
fi

echo "Cannot find install-files"
exit 1

