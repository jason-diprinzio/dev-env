#!/bin/bash

account_id=$1

if [ -z "${account_id}" ]
then
    echo "usage: `basename $0` {account id}"
    exit 1
fi

curl -i -XDELETE -uadmin@boomi.com:boomi "http://localhost:8081/partner/api/rest/v1/boomi-internal/Account/${account_id}"

