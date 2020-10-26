#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: setup_guacamole.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.04.28
# Revision...: 
# Purpose....: Script to setup the guacamole docker stack.
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
export EMAIL=${EMAIL:-""}   # Adding a valid address is strongly recommended
export HOSTNAME=${HOSTNAME:-$(hostname)}
export DOMAINNAME=${DOMAINNAME:-"trivadislabs.com"}
export STAGING_ENABLE=${STAGING_ENABLE:-0} # Set to 1 if you're testing your setup to avoid hitting request limits
GUACAMOLE_USER="avocado"
GUACADMIN_USER="guacadmin"
#export GUACADMIN_PASSWORD="LAB42-Schulung"
GUACADMIN_PASSWORD=""
# - EOF Variables -----------------------------------------------------------

# - Functions ---------------------------------------------------------------
function command_exists () {
# Purpose....: check if a command exists. 
# ---------------------------------------------------------------------------
    command -v $1 >/dev/null 2>&1;
}

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
# - EOF Functions -----------------------------------------------------------

echo "INFO: Start to config guacamole stack at $(date)" 

# check if we do have a docker-compose
if ! command_exists docker-compose; then
    echo "ERR : docker-compose isn't installed/available on this system..."
    exit 1
fi

# check if we do have a docker-compose
if ! command_exists docker; then
    echo "ERR : docker isn't installed/available on this system..."
    exit 1
fi

echo "INFO: Pull the latest docker image ------------------------------------"
# Pull the required images
docker pull guacamole/guacamole
docker pull guacamole/guacd
docker pull mysql/mysql-server
docker pull nginx
docker pull certbot/certbot

# Generate guacadmin password
if [ -z ${GUACADMIN_PASSWORD} ]; then
    # Auto generate a password
    echo "- auto generate new ${GUACADMIN_USER} password..."
    GUACADMIN_PASSWORD=$(pwgen -s -1 12)
fi

# get the guacamole git repo
su -l avocado -c "cd /home/avocado; git clone https://github.com/oehrlis/guacamole.git"
# Update guacadmin password
sed -i "s/^GUACADMIN_PASSWORD.*/GUACADMIN_PASSWORD=${GUACADMIN_PASSWORD}/" ${SCRIPT_BASE}/.env
sed -i "s/^NGINX_HOST.*/NGINX_HOST=${HOSTNAME}/" ${SCRIPT_BASE}/.env

# run preparation 
${SCRIPT_BASE}/bin/prepare_initdb.sh

# start guacamole containers
cd ${SCRIPT_BASE}
docker-compose up -d guacamole mysql guacd

# run init-letsencrypt  
${SCRIPT_BASE}/bin/prepare_certs.sh

# start guacamole containers
docker-compose up -d

echo "INFO: Finish to config guacamole stack at $(date)" 
# --- EOF --------------------------------------------------------------------