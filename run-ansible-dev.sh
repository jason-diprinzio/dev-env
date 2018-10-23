#!/bin/bash

. /home/jason/Applications/ansible1.9/bin/activate

version=`find engine/target -name "*war" -type f | xargs basename | sed -e 's/.war//' | awk -F- '{print $3"-"$4}'`
pushd /home/jason/Projects/relutil/scripts/src/main/ansible
git pull
ansible-playbook -i dev platform_properties.yml  --extra-vars "version=${version}"
result=$?
popd

