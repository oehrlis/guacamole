#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: bootstrap_bastion.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.04.28
# Revision...: 
# Purpose....: Script to bootstrap the jumphost respectively bastion host.
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
export SCRIPT_BASE="$(dirname ${ORADBA_BIN})"
echo "INFO: Start to config guacamole at $(date)" 

echo "INFO: Get postgres config ------------------------------------------------"
mkdir -p ${SCRIPT_BASE}/config/postgres >/dev/null 2>&1
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgres > ${SCRIPT_BASE}/config/postgres/initdb.sql

echo "INFO: Finish to config guacamole at $(date)" 
# --- EOF --------------------------------------------------------------------