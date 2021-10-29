#!/bin/sh
# ---------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: renew_certbot.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.04.28
# Revision...: 
# Purpose....: Script to renew the certbot.
# Notes......: --
# Reference..: --
# ---------------------------------------------------------------------------
# Define a bunch of bash option see 
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -o nounset          # stop script after 1st cmd failed
set -o errexit          # exit when 1st unset variable found
set -o pipefail         # pipefail exit after 1st piped commands failed

export SCRIPT_NAME=$(basename "$0")
export WAIT2RENEW=${WAIT2RENEW:-"6h"}
echo "INFO: Start ${SCRIPT_NAME} at $(date) and wait for ${WAIT2RENEW}" 

# define signal to terminate
trap exit TERM

# define a endless loop
while :; do 
    echo "INFO: renew certbot at $(date)"
    certbot renew
    sleep ${WAIT2RENEW} & wait $!
done

echo "INFO: Finish to config guacamole at $(date)" 
# --- EOF --------------------------------------------------------------------