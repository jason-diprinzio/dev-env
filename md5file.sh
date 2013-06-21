#!/bin/bash

file=$1

if [ -z "$file" ]
then
    exit 1
fi


md5sum $1 | awk '{print $1}' | chop > $1.MD5

