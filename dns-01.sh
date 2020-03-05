#!/usr/bin/env bash

function CHECK_QUIT_SIGNAL() {
    local SIGNAL_FILE="/tmp/_acme-signal-file"
    if [ -f "${SIGNAL_FILE}" ]; then
        echo "FILE EXISTS, REMOVING..."
        rm -rf "${SIGNAL_FILE}"
        exit 0
    fi
}

function DEBUG_LOG() {
    local LOG_FILE_NAME="/root/lets-encrypt-debug.log"
    local TIME
    TIME=$(date)

    echo "TIME: ${TIME}" >>"${LOG_FILE_NAME}"
    echo "CERTBOT_DOMAIN                : ${CERTBOT_DOMAIN}" >>"${LOG_FILE_NAME}"
    echo "CERTBOT_VALIDATION            : ${CERTBOT_VALIDATION}" >>"${LOG_FILE_NAME}"
    echo "CERTBOT_TOKEN(HTTP-01)        : ${CERTBOT_TOKEN}" >>"${LOG_FILE_NAME}"
    echo "CERTBOT_AUTH_OUTPUT(cleanup)  : ${CERTBOT_AUTH_OUTPUT}" >>"${LOG_FILE_NAME}"
    echo "-------------------------------------------------------" >>"${LOG_FILE_NAME}"
    echo "" >>"${LOG_FILE_NAME}"
    echo "" >>"${LOG_FILE_NAME}"
    echo "" >>"${LOG_FILE_NAME}"
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

function QUERY_DNS_TXT_RECORD() {
    local DOMAIN_NAME=$1
    RES=$(dig -t txt "${DOMAIN_NAME}" @8.8.8.8 +trace | grep "${DOMAIN_NAME}" | grep --color "TXT")
    echo "${RES}"
    return $?
}

function CHECK_ACME_CHALLENGE_RESULT() {
    local DOMAIN_NAME=$1
    local VALIDATION=$2
    local CHECK_RESULT

    CHECK_RESULT=$(QUERY_DNS_TXT_RECORD "_acme-challenge.${DOMAIN_NAME}" | grep --color -c "${VALIDATION}")
    echo "${CHECK_RESULT}"
}

function POLL() {
    local CHECK_DOMAIN=$1
    local CHECK_VALIDATION=$2

    local MAX=1000
    local MIN_CONTINUOUS_COUNT=20
    local CURRENT=1

    for ((CONTINUOUS_SUCCESS = 0; CONTINUOUS_SUCCESS < MIN_CONTINUOUS_COUNT; CURRENT++)); do
        if [ -n "$(CHECK_ACME_CHALLENGE_RESULT "${CHECK_DOMAIN}" "${CHECK_VALIDATION}")" ]; then
            echo "ROUND: ${CURRENT}, SUCCESS"
            CONTINUOUS_SUCCESS ++
        else
            echo "ROUND: ${CURRENT}"
            CONTINUOUS_SUCCESS=0
        fi
        if [ ${CURRENT} -gt ${MAX} ]; then
            echo "MAX RETRIES ${MAX} REACHED. TERMINATED"
            exit 1
        fi
        sleep 2
        CHECK_QUIT_SIGNAL
    done

#    for ((integer = 1; integer > $(CHECK_ACME_CHALLENGE_RESULT "${CHECK_DOMAIN}" "${CHECK_VALIDATION}"); CURRENT++)); do
#        echo "ROUND: ${CURRENT}"
#
#        if [ ${CURRENT} -gt ${MAX} ]; then
#            echo "MAX RETRIES ${MAX} REACHED. TERMINATED"
#            exit 1
#        fi
#        sleep 2
#        CHECK_QUIT_SIGNAL
#    done

    echo "CHECK FINISHED AFTER POLLING ${CURRENT} TIMES"
    exit 0
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
