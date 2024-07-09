#!/bin/bash 
APP_NAME=''
DOMAIN=''
HOST=''

check_input(){
    if [ -z "${1}" ]; then
        echo "var1 is empty"
        exit 1
    fi
}

check_input ${1}
while [ ! -z "${1}" ]; do
    case ${1} in
        -[hH] | -host | --host) shift
            check_input "${1}"
            HOST="${1}"
            ;;
        -[aA] | -app | --app) shift
            check_input "${1}"
            APP_NAME="${1}"
            ;;
        -[dD] | -domain | --domain) shift
            check_input "${1}"
            DOMAIN="${1}"
            ;;          
        *) 
            echo "HELP"
            ;;              
    esac
    shift
done

echo "var1 is ${1}"
echo "App_Name is ${APP_NAME}"
echo "Domain is ${DOMAIN}"