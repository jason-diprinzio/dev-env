#!/bin/bash

echo "copying background image to Pictures directory"
cp 26d7fc7a2b6c04ab74f06b301bbdf88f7bfd.jpg ~/Pictures

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


