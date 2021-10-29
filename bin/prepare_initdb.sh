#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: bootstrap_bastion.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.04.28
# Revision...: 
# Purpose....: Script to prepere the init db scripts.
# Notes......: --
# Reference..: --
# ---------------------------------------------------------------------------
# Define a bunch of bash option see 
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -o nounset          # stop script after 1st cmd failed
set -o errexit          # exit when 1st unset variable found
set -o pipefail         # pipefail exit after 1st piped commands failed

export SCRIPT_NAME=$(basename "$0")
export SCRIPT_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
export SCRIPT_BASE="$(dirname ${SCRIPT_BIN})"

# -----------------------------------------------------------------------
function gen_password {
# Purpose....: generate a password string
# -----------------------------------------------------------------------
    Length=${1:-12}

    # make sure, that the password length is not shorter than 4 characters
    if [ ${Length} -lt 4 ]; then
        Length=4
    fi

    # generate password
    if [ $(command -v pwgen) ]; then 
        pwgen -s -1 ${Length}
    else 
        while true; do
            # use urandom to generate a random string
            s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w ${Length} | head -n 1)
            # check if the password meet the requirements
            if [[ ${#s} -ge ${Length} && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]; then
                echo "$s"
                break
            fi
        done
    fi
}

echo "INFO: Start to config guacamole at $(date)" 

echo "INFO: Get mysql config ------------------------------------------------"
mkdir -p ${SCRIPT_BASE}/config/mysql >/dev/null 2>&1
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > ${SCRIPT_BASE}/config/mysql/00_initdb.sql

echo "INFO: Define passwords ------------------------------------------------"
. ${SCRIPT_BASE}/.env

if [ -z ${MYSQL_PASSWORD} ]; then
    # Auto generate a password
    echo "- auto generate new mysql password..."
    MYSQL_PASSWORD=$(gen_password)
    sed -i "s/^MYSQL_PASSWORD.*/MYSQL_PASSWORD=${MYSQL_PASSWORD}/" ${SCRIPT_BASE}/.env
fi

if [ -z ${GUACADMIN_PASSWORD} ]; then
    # Auto generate a password
    echo "- auto generate new password..."
    GUACADMIN_PASSWORD=$(gen_password)
    sed -i "s/^GUACADMIN_PASSWORD.*/GUACADMIN_PASSWORD=${GUACADMIN_PASSWORD}/" ${SCRIPT_BASE}/.env
fi

# update config script
sed -i "s/GUACADMIN_PASSWORD/${GUACADMIN_PASSWORD}/" ${SCRIPT_BASE}/config/mysql/01_configure.sql
echo "INFO: Finish to config guacamole at $(date)" 
# --- EOF --------------------------------------------------------------------