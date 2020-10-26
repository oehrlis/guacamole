# Scripts

This folder contains several scripts to prepare and configure the guacamole docker stack.

- [prepare_certs.sh](prepare_certs.sh) Script to prepare the letsencrypt certificate challenge. It will create a dummy certificate, start nginx, delete the dummy and request the real certificates. The guacamole backend has to be started first. Otherwise nginx will fail.
- [prepare_initdb.sh](prepare_initdb.sh) Script prepare the initdb scripts based on the guacamole images. The corresponding scripts are copied from the docker image.
