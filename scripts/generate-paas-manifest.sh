#!/usr/bin/env bash

#define parameters which are passed in.
APPLICATION_NAME=$1  # e.g. mhclg-epb-something-api-integration
STAGE=$2 # i.e. [integration, staging, production]

case "$STAGE" in
 production) MEMORY="2G" ;;
 *) MEMORY="1G" ;;
esac

case "$STAGE" in
 production) DATABASE="mhclg-epb-db-production" ;;
 *) DATABASE="dluhc-epb-db-$STAGE" ;;
esac

cat << EOF
---
applications:
  - name: $APPLICATION_NAME
    command: null
    memory: $MEMORY
    buildpacks:
      - ruby_buildpack
    health-check-type: process
    services:
      - $DATABASE
      - dluhc-epb-redis-data-warehouse-$STAGE
      - dluhc-scale-register-api-$STAGE

EOF
