#!/usr/bin/env bash

#define parameters which are passed in.
APPLICATION_NAME=$1  # e.g. dluhc-epb-worker-integration
STAGE=$2 # i.e. [integration, staging, production]
DATABASE="dluhc-epb-db-$STAGE"

case "$STAGE" in
 production) MEMORY="3G" ;;
 *) MEMORY="512M";;
esac

cat << EOF
---
applications:
  - name: $APPLICATION_NAME
    memory: $MEMORY
    instances: 1
    command: bundle exec sidekiq -r ./sidekiq/config.rb
    no-route: true
    buildpacks:
      - nodejs_buildpack
      - ruby_buildpack
    health-check-type: process
    services:
      - dluhc-epb-redis-sidekiq-$STAGE
      - $DATABASE
      - mhclg-epb-s3-open-data-export
EOF
