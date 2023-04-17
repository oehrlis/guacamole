#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: setup_guacamole.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.04.28
# Revision...: 
# Purpose....: Script to setup the guacamole docker stack.
# Notes......: --
# Reference..: --
# ---------------------------------------------------------------------------

# - Customization -----------------------------------------------------------
export HOSTNAME=${HOSTNAME:-$(hostname)}                # Hostname for the bastion host
export DOMAINNAME=${DOMAINNAME:-"trivadislabs.com"}     # Domainname for the bastion host
export EMAIL=${EMAIL:-"admin@${DOMAINNAME}"}            # Adding a valid address is strongly recommended
export STAGING_ENABLE=${STAGING_ENABLE:-0}              # Set to 1 if you're testing your setup to avoid hitting request limits
export GUACAMOLE_USER=${GUACAMOLE_USER:-"avocado"}
export GUACAMOLE_BASE=${GUACAMOLE_BASE:-"/home/${GUACAMOLE_USER}/guacamole"}
export GUACADMIN_USER=${GUACADMIN_USER:-"guacadmin"}    # guacadmin user name   
export GUACADMIN_PASSWORD=${GUACADMIN_PASSWORD:-""}     # Password for the guacadmin user
# - End of Customization ----------------------------------------------------

# - Default Values ----------------------------------------------------------
export SCRIPT_NAME=$(basename "$0")
export SCRIPT_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
export SCRIPT_BASE="$(dirname ${SCRIPT_BIN})"
export GITHUP_REPO="https://github.com/oehrlis/guacamole.git"
TIMESTAMP=$(date "+%Y.%m.%d_%H%M%S")
# define logfile and logging
LOG_BASE=${LOG_BASE:-"/home/${GUACAMOLE_USER}"}
readonly LOGFILE="${LOG_BASE}/$(basename ${SCRIPT_NAME} .sh)_${TIMESTAMP}.log"
# - EOF Default Values ------------------------------------------------------

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

# - Initialization ----------------------------------------------------------
# Define a bunch of bash option see 
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -o nounset          # stop script after 1st cmd failed
set -o errexit          # exit when 1st unset variable found
set -o pipefail         # pipefail exit after 1st piped commands failed

# initialize logfile
touch ${LOGFILE} 2>/dev/null
exec &> >(tee -a "$LOGFILE") # Open standard out at `$LOG_FILE` for write.     
exec 2>&1               # Redirect standard error to standard out 

echo "INFO: Start to config guacamole stack at $(date)" 

# check if we do have docker-compose docker and git
for c in docker-compose docker git; do
    if ! command_exists ${c}; then
        echo "ERR : ${c} isn't installed/available on this system..."
        exit 1
    fi
done

# check if we do have the git repo
if [ -d "${GUACAMOLE_BASE}" ];then
    cd ${GUACAMOLE_BASE}
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        git pull                                # pull the latest updates
    else
        echo "ERR : ${GUACAMOLE_BASE} isn't a git work tree ..."
        exit 1
    fi
else
    INSTALL_BASE=$(dirname ${GUACAMOLE_BASE})
    if [ -d "${INSTALL_BASE}" ]; then
        cd ${INSTALL_BASE}
        git clone ${GITHUP_REPO}                # clone the repo
    else
        echo "ERR : can't access ${INSTALL_BASE} ..."
        exit 1
    fi
fi

# - Main --------------------------------------------------------------------
echo "INFO: Pull the latest docker image ------------------------------------"
# Pull the required images
docker pull guacamole/guacamole:1.4.0
docker pull guacamole/guacd:1.4.0
docker pull mysql/mysql-server:8.0
docker pull nginx
docker pull certbot/certbot
docker pull kylemanna/openvpn

# Generate guacadmin password
if [ -z ${GUACADMIN_PASSWORD} ]; then
    # Auto generate a password
    echo "- auto generate new ${GUACADMIN_USER} password..."
    GUACADMIN_PASSWORD=$(gen_password 12)
fi

# Update guacadmin password
sed -i "s/^GUACADMIN_PASSWORD.*/GUACADMIN_PASSWORD=${GUACADMIN_PASSWORD}/" ${GUACAMOLE_BASE}/.env

# run preparation 
${GUACAMOLE_BASE}/bin/prepare_initdb.sh

# start guacamole containers
cd ${GUACAMOLE_BASE}
docker-compose up -d guacamole mysql guacd

echo "exit before prepare_certs.sh"
exit
# run init-letsencrypt  
${GUACAMOLE_BASE}/bin/prepare_certs.sh

# prepare openvpn 
echo "INFO: Configure OpenVPN -----------------------------------------------"
docker-compose run --rm openvpn ovpn_genconfig -u "udp://${HOSTNAME}.${DOMAINNAME}" -p "push route 10.0.1.0 255.255.255.0"
echo "${HOSTNAME}.${DOMAINNAME}"|docker-compose run --rm openvpn ovpn_initpki nopass
docker-compose run --rm openvpn easyrsa build-client-full ${HOSTNAME} nopass
docker-compose run --rm openvpn ovpn_getclient ${HOSTNAME} >$SCRIPT_BASE/${HOSTNAME}.ovpn
echo "pull" >>$SCRIPT_BASE/${HOSTNAME}.ovpn
echo "tls-client" >>$SCRIPT_BASE/${HOSTNAME}.ovpn
echo "remote ${HOSTNAME}.${DOMAINNAME}">>$SCRIPT_BASE/${HOSTNAME}.ovpn

# start guacamole containers
docker-compose up -d

echo "INFO: Finish to config guacamole stack at $(date)" 
# --- EOF --------------------------------------------------------------------