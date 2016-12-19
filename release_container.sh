#!/bin/bash

version=$(get_atom_version)
atom=$1

#if [ -z "$version"  ]
#then
#    echo `basename $0`  "[atomid]"
#    exit 1
#fi

if [ -n "$atom" ]
then
    atom="?atomIds="$atom
fi

echo -n "Release atom version ${version}? [y\\N] "
read answer

echo

if [  "${answer}" == "y" ]
then
    echo "Installing version ${version}"
    curl -i -uadmin@boomi.com:boomi  http://localhost:8081/update/PackageDownload/${version}${atom}
else
    echo "Aborting"
fi

