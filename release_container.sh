#!/bin/bash

version=$1
atom=$2

if [ -z "$version"  ]
then
    echo `basename $0`  "<version> [atomid]"
    exit 1
fi

if [ -n "$atom" ]
then
    atom="?atomIds="$atom
fi

curl -i -uadmin@boomi.com:boomi  http://localhost:8081/update/PackageDownload/${version}${atom}

