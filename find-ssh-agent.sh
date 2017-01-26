#!/bin/bash

agentsock=`find /tmp -name agent.* 2>/dev/null | xargs ls -ltr | awk '{print $9}'`
agentpid=`pgrep -fl ssh-agent | awk '{print $1}'`

if [ -n "$agentsock" ]
then
    if [ -n "$agentpid" ]
    then
        export SSH_AUTH_SOCK=$agentsock
        export SSH_AGENT_PID=$agentpid
    else
        ssh-agent
    fi
fi

