#!/usr/bin/env bash

SIGNAL_FILE="/tmp/_acme-signal-file"

function CHECK_QUIT_SIGNAL() {
    if [ -f "${SIGNAL_FILE}" ]; then
        echo "Signal file exists, now quitting..."
        CLEAR_QUIT_SIGNAL
        exit 0
    fi
}
function SET_QUIT_SIGNAL() {
    touch "${SIGNAL_FILE}"
}

function CLEAR_QUIT_SIGNAL() {
    rm -rf "${SIGNAL_FILE}"
}

function QUERY_DNS_TXT_RECORD() {
    local DOMAIN_NAME=$1
    RES=$(dig -t txt "${DOMAIN_NAME}" @8.8.8.8 +trace | grep "${DOMAIN_NAME}" | grep --color "TXT")
    echo "${RES}"
}

function CHECK_ACME_CHALLENGE_RESULT() {
    local DOMAIN_NAME=$1
    local VALIDATION=$2
    local CHECK_RESULT

    CHECK_RESULT=$(QUERY_DNS_TXT_RECORD "_acme-challenge.${DOMAIN_NAME}" | grep --color -c "${VALIDATION}")
    echo "${CHECK_RESULT}"
}

function DEBUG_LOG() {
    local YMD_FOR_FILENAME=$(date +"%Y%m%d_%H%M%S")
    local YMD_FOR_HUMAN=$(date +"%Y-%m-%d %H:%M:%S")
    local LOG_FILE_NAME="/root/lets-encrypt-debug.log"

    echo "TIME: ${TIME_FOR_HUMAN}" >>"${LOG_FILE_NAME}"
    echo "CERTBOT_DOMAIN                : ${CERTBOT_DOMAIN}" >>"${LOG_FILE_NAME}"
    echo "CERTBOT_VALIDATION            : ${CERTBOT_VALIDATION}" >>"${LOG_FILE_NAME}"
    echo "CERTBOT_TOKEN(HTTP-01)        : ${CERTBOT_TOKEN}" >>"${LOG_FILE_NAME}"
    echo "CERTBOT_AUTH_OUTPUT(cleanup)  : ${CERTBOT_AUTH_OUTPUT}" >>"${LOG_FILE_NAME}"
    echo "-------------------------------------------------------" >>"${LOG_FILE_NAME}"
    echo "" >>"${LOG_FILE_NAME}"
    echo "" >>"${LOG_FILE_NAME}"
    echo "" >>"${LOG_FILE_NAME}"
}

function POLL() {
    local CHECK_DOMAIN=$1
    local CHECK_VALIDATION=$2

    local MAX=1000
    local MIN_CONTINUOUS_COUNT=20
    local CURRENT=1

    local CHECK_RESULT=""

    for ((CONTINUOUS_SUCCESS = 0; CONTINUOUS_SUCCESS < MIN_CONTINUOUS_COUNT; CURRENT++)); do
        CHECK_RESULT="$(CHECK_ACME_CHALLENGE_RESULT "${CHECK_DOMAIN}" "${CHECK_VALIDATION}")";
        if [ "${CHECK_RESULT}" -gt 0 ]; then
            echo "ROUND ${CURRENT}: V"
            CONTINUOUS_SUCCESS=${CONTINUOUS_SUCCESS}+1
        else
            echo "ROUND ${CURRENT}: X"
            CONTINUOUS_SUCCESS=0
        fi
        if [ ${CURRENT} -gt ${MAX} ]; then
            echo "MAX RETRIES ${MAX} REACHED. TERMINATED"
            exit 1
        fi
        sleep 2
        CHECK_QUIT_SIGNAL
    done

    echo "CHECK FINISHED AFTER POLLING ${CURRENT} TIMES"
    exit 0
}

# Test listed below:

#echo "Result of QUERY_DNS_TXT_RECORD: "
#QUERY_DNS_TXT_RECORD "_acme-challenge.stgmsa.me"

#echo ""
#echo "Result of CHECK_ACME_CHALLENGE_RESULT: "
#CHECK_ACME_CHALLENGE_RESULT "stgmsa.me" "syauigdhad"

#echo ""
#echo "Result of POLL: "
#POLL "stgmsa.me" "syauigdhad"
