# Docker based Guacamole Configuration

This repository contains the mock example for setting up a docker-based guacamole server with an nginx reverse proxy and let's encrypt certificates. The purpose of this project is to provide a guacamole server on OCI bastion hosts for Trivadis Training environments. It is based on the following official docker images:

- [guacamole/guacamole-server](https://hub.docker.com/r/guacamole/guacamole) Apache Guacamole is a clientless remote desktop gateway supporting protocols like VNC and RDP..
- [guacamole/guacd](https://hub.docker.com/r/guacamole/guacd) The native server-side proxy used by Apache Guacamole.
- [mysql/mysql-server](https://hub.docker.com/r/mysql/mysql-server) Optimized MySQL Server Docker images. Created, maintained and supported by the MySQL team at Oracle.
- [nginx](https://hub.docker.com/_/nginx) Official build of Nginx.
- [certbot/certbot](https://hub.docker.com/r/certbot/certbot) Official build of EFF's Certbot tool for obtaining TLS/SSL certificates from Let's Encrypt.

## Installation

1. Install `docker` and `docker-compose`. See [Install Docker Compose](https://docs.docker.com/compose/install/#install-compose)

2. Clone this repository: `git clone https://github.com/oehrlis/guacamole.git`.

3. Modify configuration
   - Update the `.env` or define the corresponding environment variables.
   - Review and update `docker-compose.yml` 
   - Define the following environment variables:
     - *EMAIL* - Adding a valid address for certificate renewal (default none)
     - *HOSTNAME* - Define a hostname for the nginx server and certificate name (default: `$(hostname)`)
     - DOMAINNAME - Define a domain name for nginx server and certificate name (default: *trivadislabs.com*)
     - STAGING_ENABLE - Set STAGING to 1 if you're testing your setup to avoid hitting request limits is certification

4. Run the script `prepare_initdb.sh` to prepare the database initialisation scripts

    ```bash
    cd guacamole
    ./bin/prepare_initdb.sh
    ```

5. Startup the guacamole services. Currently required to make nginx happy.

    ```bash
    docker-compose up -d guacamole mysql guacd
    ```

6. Run the script `prepare_certs.sh` to initiate an initial certification request.

    ```bash
    export EMAIL="info@example.org"
    export STAGING_ENABLE=1
    ./bin/prepare_certs.sh
    ```

7. Finally start all container

    ```bash
    docker-compose up -d
    ```

## Issues

Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/).

* [Questions](https://github.com/oehrlis/guacamole/issues?q=is%3Aissue+label%3Aquestion)
* [Open enhancements](https://github.com/oehrlis/guacamole/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement)
* [Open bugs](https://github.com/oehrlis/guacamole/issues?q=is%3Aopen+is%3Aissue+label%3Abug)
* [Submit new issue](https://github.com/oehrlis/guacamole/issues/new)

## How to Contribute

1. Describe your idea by [submitting an issue](https://github.com/oehrlis/guacamole/issues/new)
2. [Fork this respository](https://github.com/oehrlis/guacamole/fork)
3. [Create a branch](https://help.github.com/articles/creating-and-deleting-branches-within-your-repository/), commit and publish your changes and enhancements
4. [Create a pull request](https://help.github.com/articles/creating-a-pull-request/)

## License

Copyright (c) 2019, 2020 Trivadis AG and/or its associates. All rights reserved.

The Trivadis Terraform modules are licensed under the Apache License, Version 2.0. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.

## Related Documentation, Blog

- [step-by-step guide on how to set up nginx and Let’s Encrypt with Docker](https://medium.com/@pentacent/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71)
- [Terraform OCI Provider Documentation](https://www.terraform.io/docs/providers/oci/index.html)
- [Terraform Creating Modules](https://www.terraform.io/docs/modules/index.html)
