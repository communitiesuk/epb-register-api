#!/usr/bin/env bash

#define parameters which are passed in.
APPLICATION_NAME=$1  # e.g. mhclg-epb-something-api-integration
STAGE=$2 # i.e. [integration, staging, production]

case "$STAGE" in
 production) MEMORY="2G" ;;
 *) MEMORY="1G" ;;
esac

cat << EOF
---
applications:
  - name: $APPLICATION_NAME
    command: null
    memory: $MEMORY
    buildpacks:
      - ruby_buildpack
    health-check-type: http
    health-check-http-endpoint: /healthcheck
    services:
      - mhclg-epb-db-$STAGE

EOF
