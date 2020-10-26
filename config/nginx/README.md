# Nginx Scripts and Config Files

This folder contains several config files and scripts to configure *nginx* container.

- [nginx.conf](nginx.conf) Default nginx configuration file.
- [guacamole.conf.template](guacamole.conf.template) Ngnix template for the guacamole reverse proxy. This file include environment variables which will be resolved using `envsubst` see also [environment variables](https://hub.docker.com/_/nginx).
  - *NGINX_HOST*, is the hostname used to setup nginx and initiate the certificat requests (default: ${HOSTNAME}.trivadislabs.com)
  - *NGINX_PROXYSERVER*, is used to define a proxy server for all request to `/`.
  - *GUACAMOLE_SERVER*, hostname of the guacamole backend server (default: *guacamole*)
