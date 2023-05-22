#!/usr/bin/env bash

#define parameters which are passed in.
APPLICATION_NAME=$1  # e.g. mhclg-epb-something-api-integration
STAGE=$2 # i.e. [integration, staging, production]
DATABASE="dluhc-epb-db-$STAGE"

case "$STAGE" in
 production) MEMORY="4G" ;;
 *) MEMORY="1G" ;;
esac

cat << EOF
---
applications:
  - name: $APPLICATION_NAME
    command: null
    memory: $MEMORY
    buildpacks:
      - nodejs_buildpack
      - ruby_buildpack
    health-check-type: http
    health-check-http-endpoint: /healthcheck
    health-check-invocation-timeout: 2
    services:
      - $DATABASE
      - dluhc-epb-redis-data-warehouse-$STAGE
      - dluhc-scale-register-api-$STAGE
      - mhclg-epb-s3-open-data-export

EOF
