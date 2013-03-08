#!/bin/sh
#
# Defaults
ACCOUNTNAME="TestAccount"
EMAIL="admin@boomi.com"
FIRSTNAME="Bob"
LASTNAME="Smith"
PHONE="1239873625"
COUNTRYCODE="US"
PARENTACCOUNTID="boomi-internal"
EDITION="regular"
TRIALLENGTH="2000"
B2BENABLED="false"
CLOUDENABLED="true"
THREADINGENABLED="true"
NUMBEROFMOLECULES="100"
ENVIRONMENTSENABLED="false"
WIDGETSENABLED="false"
OVERRIDESENABLED="false"
SMALLBUSINESSCONNECTIONS="100"
STANDARDCONNECTIONS="100"
ENTERPRISECONNECTIONS="100"
TRADINGPARTNERCONNECTIONS="100"
POPULATEPROCESSLIBRARY="false"
ADDACCOUNTFOREXISTINGUSER="true"
SUPPORTACCESS="true"
SUPPORTLEVEL="standard"
WSENABLED="true"

DEBUG=0

die_usage()
{
    echo "usage: `basename $0` [--debug] |"
    echo "                     [--account={string}]"
    echo "                     [--email={string}]"
    echo "                     [--firstname={string}]"
    echo "                     [--lastname={string}]"
    echo "                     [--phone={string}]"
    echo "                     [--countrycode={string}]"
    echo "                     [--parentaccount={string}]"
    echo "                     [--edition={regular|personal|partner_trial}]"
    echo "                     [--triallength={number}]"
    echo "                     [--b2b={true|false}]"
    echo "                     [--cloud={true|false}]"
    echo "                     [--threading={true|false}]"
    echo "                     [--nummolecules={number}]"
    echo "                     [--environments={true|false}]"
    echo "                     [--widgets={true|false}]"
    echo "                     [--overrides={true|false}]"
    echo "                     [--sbconnections={number}]"
    echo "                     [--stdconnections={number}]"
    echo "                     [--enterpriseconns={number}]"
    echo "                     [--tpconnections={number}]"
    echo "                     [--proclib={true|false}]"
    echo "                     [--addacct4user={true|false}]"
    echo "                     [--supportaccess={number}]"
    echo "                     [--supportlevel={standard|premeier}]"
    echo "                     [--webservices={true|false}]"
    exit $1
}

check_arg()
{
    if [ -z "$1" ]
    then
        echo $2" cannot be empty."
        exit 2
    fi
}

while getopts ":h-:" opt; do
    case "${opt}" in
        -)
            case "${OPTARG}" in
                account=*)
                    ACCOUNTNAME="${OPTARG#*=}"
                    check_arg "${ACCOUNTNAME}" "account"
                    ;;
                email=*)
                    EMAIL="${OPTARG#*=}"
                    check_arg "${EMAIL}" "email"
                    ;;
                firstname=*)
                    FIRSTNAME="${OPTARG#*=}"
                    check_arg "${FIRSTNAME}" "firstname"
                    ;;
                lastname=*)
                    LASTNAME="${OPTARG#*=}"
                    check_arg "${LASTNAME}" "lastname"
                    ;;
                phone=*)
                    PHONE="${OPTARG#*=}"
                    check_arg "${PHONE}" "phone"
                    ;;
                countrycode=*)
                    COUNTRYCODE="${OPTARG#*=}"
                    check_arg "${COUNTRYCODE}" "countrycode"
                    ;;
                parentaccount=*)
                    PARENTACCOUNTID="${OPTARG#*=}"
                    check_arg "${PARENTACCOUNTID}" "parentaccount"
                    ;;
                edition=*)
                    EDITION="${OPTARG#*=}"
                    check_arg "${EDITION}" "edition"
                    ;;
                triallength=*)
                    TRIALLENGTH="${OPTARG#*=}"
                    check_arg "${TRIALLENGTH}" "triallength"
                    ;;
                b2b=*)
                    B2BENABLED="${OPTARG#*=}"
                    check_arg "${B2BENABLED}" "b2b"
                    ;;
                cloud=*)
                    CLOUDENABLED="${OPTARG#*=}"
                    check_arg "${CLOUDENABLED}" "cloud"
                    ;;
                threading=*)
                    THREADINGENABLED="${OPTARG#*=}"
                    check_arg "${THREADINGENABLED}" "threading"
                    ;;
                nummolecules=*)
                    NUMBEROFMOLECULES="${OPTARG#*=}"
                    check_arg "${NUMBEROFMOLECULES}" "nummolecules"
                    ;;
                environments=*)
                    ENVIRONMENTSENABLED="${OPTARG#*=}"
                    check_arg "${ENVIRONMENTSENABLED}" "environments"
                    ;;
                widgets=*)
                    WIDGETSENABLED="${OPTARG#*=}"
                    check_arg "${WIDGETSENABLED}" "widgets"
                    ;;
                overrides=*)
                    OVERRIDESENABLED="${OPTARG#*=}"
                    check_arg "${OVERRIDESENABLED}" "overrides"
                    ;;
                sbconnections=*)
                    SMALLBUSINESSCONNECTIONS="${OPTARG#*=}"
                    check_arg "${SMALLBUSINESSCONNECTIONS}" "sbconnections"
                    ;;
                stdconnections=*)
                    STANDARDCONNECTIONS="${OPTARG#*=}"
                    check_arg "${STANDARDCONNECTIONS}" "stdconnections"
                    ;;
                enterpriseconns=*)
                    ENTERPRISECONNECTIONS="${OPTARG#*=}"
                    check_arg "${ENTERPRISECONNECTIONS}" "enterpriseconns"
                    ;;
                tpconnections=*)
                    TRADINGPARTNERCONNECTIONS="${OPTARG#*=}"
                    check_arg "${TRADINGPARTNERCONNECTIONS}" "tpconnections"
                    ;;
                proclib=*)
                    POPULATEPROCESSLIBRARY="${OPTARG#*=}"
                    check_arg "${POPULATEPROCESSLIBRARY}" "proclib"
                    ;;
                addacct4user=*)
                    ADDACCOUNTFOREXISTINGUSER="${OPTARG#*=}"
                    check_arg "${ADDACCOUNTFOREXISTINGUSER}" "addacct4user"
                    ;;
                supportaccess=*)
                    SUPPORTACCESS="${OPTARG#*=}"
                    check_arg "${SUPPORTACCESS}" "supportaccess"
                    ;;
                supportlevel=*)
                    SUPPORTLEVEL="${OPTARG#*=}"
                    check_arg "${SUPPORTLEVEL}"  "supportlevel"
                    ;;
                webservices=*)
                    WSENABLED="${OPTARG#*=}"
                    check_arg "${WSENABLED}" "webservices"
                    ;;
                debug)
                    DEBUG=1
                    ;;
                help)
                    die_usage 0
                    ;;
                *)
                    echo "unknown option --${OPTARG}"
                    die_usage 1
                    ;;
            esac;;
        h)
            die_usage 0
            ;;
        *)
            echo "unknown option -${OPTARG}"
            die_usage 1
            ;;
    esac
done

DATA="<?xml version=\"1.0\" encoding=\"utf-8\"?>  \
<ProvisionAccount  \
    accountName=\"${ACCOUNTNAME}\" \
    email=\"${EMAIL}\" \
    firstName=\"${FIRSTNAME}\" \
    lastName=\"${LASTNAME}\" \
    phone=\"${PHONE}\" \
    countryCode=\"${COUNTRYCODE}\" \
    parentAccountId=\"${PARENTACCOUNTID}\" \
    edition=\"${EDITION}\" \
    trialLength=\"${TRIALLENGTH}\" \
    b2BEnabled=\"${B2BENABLED}\" \
    cloudEnabled=\"${CLOUDENABLED}\" \
    threadingEnabled=\"${THREADINGENABLED}\" \
    numberOfMolecules=\"${NUMBEROFMOLECULES}\" \
    environmentsEnabled=\"${ENVIRONMENTSENABLED}\" \
    widgetsEnabled=\"${WIDGETSENABLED}\" \
    overridesEnabled=\"${OVERRIDESENABLED}\" \
    smallBusinessConnections=\"${SMALLBUSINESSCONNECTIONS}\" \
    standardConnections=\"${STANDARDCONNECTIONS}\" \
    enterpriseConnections=\"${ENTERPRISECONNECTIONS}\" \
    tradingPartnerConnections=\"${TRADINGPARTNERCONNECTIONS}\" \
    populateProcessLibrary=\"${POPULATEPROCESSLIBRARY}\" \
    addAccountForExistingUser=\"${ADDACCOUNTFOREXISTINGUSER}\" \
    supportAccess=\"${SUPPORTACCESS}\" \
    supportLevel=\"${SUPPORTLEVEL}\" \
    wsEnabled=\"${WSENABLED}\" \
> \
</ProvisionAccount>"

if [ $DEBUG -eq 1 ]
then
    echo
    echo $DATA
    exit 0
fi

curl -uadmin@boomi.com:boomi --data "${DATA}" --header "Content-Type: application/xml" "http://toolbox:8081/provision"

