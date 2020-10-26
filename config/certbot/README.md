# Certbot Scripts and Config Files

This folder contains several config files and scripts to configure *certbot* container.

- [renew_certbot.sh](renew_certbot.sh) Entrypoint script to start the certbot. This script will automatically renew the certificate every 6h (default) or any other sleep time defined by `${WAIT2RENEW}`.
