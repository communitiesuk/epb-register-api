#!/usr/bin/env bash

#define parameters which are passed in.
APPLICATION_NAME=$1  # e.g. mhclg-epb-something-api-integration
STAGE=$2 # i.e. [integration, staging, production]

cat << EOF
---
applications:
  - name: $APPLICATION_NAME
    command: bundle exec rake cf:on_first_instance import_postcode_outcode
    memory: 1G
    buildpacks:
      - ruby_buildpack
    health-check-type: http
    health-check-http-endpoint: /healthcheck
    services:
      - mhclg-epb-db-$STAGE
      - logit-ssl-drain
EOF
