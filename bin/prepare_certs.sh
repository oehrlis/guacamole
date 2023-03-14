#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: bootstrap_bastion.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.04.28
# Revision...: 
# Purpose....: Script initiate and configure let's encrypt.
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

domains=(${HOSTNAME}.${DOMAINNAME})
data_path="${SCRIPT_BASE}/data/certbot"
rsa_key_size=4096
email_arg=""
domain_args=""
staging_arg=""
# - EOF Variables -----------------------------------------------------------

# - Functions ---------------------------------------------------------------
function command_exists () {
# Purpose....: check if a command exists. 
# ---------------------------------------------------------------------------
    command -v $1 >/dev/null 2>&1;
}
# - EOF Functions -----------------------------------------------------------

# check if we do have a docker-compose
if ! command_exists docker-compose; then
    echo "ERR : docker-compose isn't installed/available on this system..."
    exit 1
fi

echo "INFO: Start to config certs at $(date)" 
# change workding directory
cd ${SCRIPT_BASE}

# check if we do have data
if [ ! -d "$data_path" ]; then
  if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
    echo "INFO: Downloading recommended TLS parameters ..." 
    mkdir -p "$data_path/conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
    echo
  fi

  echo "INFO: Creating dummy certificate for $domains ..." 
  path="/etc/letsencrypt/live/$domains"
  mkdir -p "$data_path/conf/live/$domains"
  docker-compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:4096 -days 1\
      -keyout '$path/privkey.pem' \
      -out '$path/fullchain.pem' \
      -subj '/CN=localhost'" certbot

  echo "INFO: Starting nginx ..." 
  docker-compose up --force-recreate -d nginx

  echo "INFO: Deleting dummy certificate for $domains ..." 

  docker-compose run --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$domains && \
    rm -Rf /etc/letsencrypt/archive/$domains && \
    rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
else
  echo "INFO: Existing data found for $domains ..." 
fi

echo "INFO: Requesting Let's Encrypt certificate for $domains ..." 
#Join $domains to -d args
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate EMAIL arg
case "$EMAIL" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $EMAIL" ;;
esac

# Enable staging mode if needed
if [ $STAGING_ENABLE != "0" ]; then staging_arg="--staging"; fi

docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos --no-eff-email \
    --force-renewal" certbot || echo "WARN: Failed to get the let's encrypt certificate ..." 
    
echo "INFO: Stop nginx ..." 
docker stop nginx

echo "INFO: Finish to config certs at $(date)"
# --- EOF --------------------------------------------------------------------