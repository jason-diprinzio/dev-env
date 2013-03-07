#!/bin/bash

get_project()
{
    if [ -f pom.xml ] 
    then
        project_name=($(grep "<name>.*</name" pom.xml | sed -e 's/<[/]*name>//g' -e 's/ //g'))
        return 0
    else
        echo "No maven project found in this directory."
        return 1
    fi
}

