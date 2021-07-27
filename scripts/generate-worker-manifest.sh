#!/usr/bin/env bash

#define parameters which are passed in.
APPLICATION_NAME=$1  # e.g. mhclg-epb-something-api-integration
STAGE=$2 # i.e. [integration, staging, production]

cat << EOF
---
applications:
  - name: $APPLICATION_NAME
    memory: 256M
    instances: 1
    command: bundle exec sidekiq -r ./sidekiq/config.rb
    no-route: true
    buildpacks:
      - ruby_buildpack
    health-check-type: process
    services:
      - mhclg-epb-redis-sidekiq-$STAGE
      - mhclg-epb-db-$STAGE
EOF
