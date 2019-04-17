#!/bin/bash

echo -n ~ | grep "/Users"
ismac=$?
if [ $ismac -eq 0 ]
then
   pipe_dir=/var/folders
else
   pipe_dir=/tmp
fi

agentsock=`find "${pipe_dir}" -name 'agent.*' 2>/dev/null | xargs ls -ltr | awk '{print $9}'`
agentpid=`pgrep -fl ssh-agent | awk '{print $1}'`

if [ -n "$agentsock" ]
then
    if [ -n "$agentpid" ]
    then
        unset SSH_AUTH_SOCK
        unset SSH_AGENT_PID
        export SSH_AUTH_SOCK=$agentsock
        export SSH_AGENT_PID=$agentpid
    else
        ssh-agent
    fi
fi

