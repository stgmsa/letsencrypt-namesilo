#!/usr/bin/env bash
. lib.sh

function DNS_LIST_RECORDS() {
    local DOMAIN_NAME=$1

    local ACTION="dnsListRecords"
    local BASE_URL
    BASE_URL="$(GET_API_BASE_URL ${ACTION})"
    local API
    API="${BASE_URL}&domain=${DOMAIN_NAME}"

    local RES
    RES=$(curl -X GET "${API}" 2>/dev/null)
    echo "${RES}"
    return $?
}

function GET_API_BASE_URL() {
    local API_KEY="" # FILL YOUR NAMESILO API KEY HERE TO OVERRIDE NAMESILO API KEY AUTO DETECTION.
    local VERSION="1"
    local TYPE="xml"
    local API_BASE_URL="https://www.namesilo.com/api"

    local ACTION=$1
    local API_KEY_AUTO_DETECT=""

    API_KEY_AUTO_DETECT="$(FIND_NAMESILO_API_KEY_FROM_PWD)"
    if [ -n "${API_KEY_AUTO_DETECT}" ] && [ -z "${API_KEY}" ]; then
        API_KEY=${API_KEY_AUTO_DETECT}
    fi

    local URL="${API_BASE_URL}/${ACTION}?version=${VERSION}&type=${TYPE}&key=${API_KEY}"
    echo "${URL}"
    return 0
}

function ADD_RECORD() {
    local DOMAIN_NAME=$1
    local RR_TYPE=$2
    local RR_HOST=$3
    local RR_VALUE=$4
    local RR_TTL=$5

    local ACTION="dnsAddRecord"
    local BASE_URL
    BASE_URL="$(GET_API_BASE_URL ${ACTION})"
    local API
    API="${BASE_URL}&domain=${DOMAIN_NAME}&rrtype=${RR_TYPE}&rrhost=${RR_HOST}&rrvalue=${RR_VALUE}&rrttl=${RR_TTL}"

    local RES
    RES=$(curl -X GET "${API}" 2>/dev/null)
    echo "${RES}"
    return $?
}

function FIND_NAMESILO_API_KEY_FROM_PWD() {
    local PWD=""
    local NAMESILO_API_KEY_FILE=""
    local NAMESILO_API_KEY=""

    PWD="$(pwd)"
    NAMESILO_API_KEY_FILE="$(ls -la $PWD | grep "NAMESILO-API-KEY-")"

    if [ -n "${NAMESILO_API_KEY_FILE}" ]; then
        NAMESILO_API_KEY="$(echo $NAMESILO_API_KEY_FILE | awk '{print $NF}' | awk -F '-' '{print $NF}')"
        echo $NAMESILO_API_KEY
        return $?
    fi
}

DEBUG_LOG
ADD_RECORD "stgmsa.me" "TXT" "_acme-challenge" "${CERTBOT_VALIDATION}" "3600"
POLL "${CERTBOT_DOMAIN}" "${CERTBOT_VALIDATION}"

# Test:
# POLL "stgmsa.me" "AaabzW4ibDxfctmGJWwktC7OvqyFLzE3T_wku5DzZBM"
