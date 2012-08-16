#!/bin/bash

function mk_tags() {
for dir in $dirs
do 
    echo $dir; ctags --append -R $dir 
done
}

rm tags 2>/dev/null

dirs=`find . -name java -type d | grep -v generated`
mk_tags

dirs=`find . -name generated-sources -type d`
mk_tags

