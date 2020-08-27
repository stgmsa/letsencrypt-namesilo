#!/usr/bin/env bash
. lib.sh

DEBUG_LOG
POLL "${CERTBOT_DOMAIN}" "${CERTBOT_VALIDATION}"
