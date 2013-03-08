#!/bin/bash

today=`date +%y_%m_%d`

find logs -name "*.log" | grep -v "${today}" | xargs rm -f

