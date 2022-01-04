#!/usr/bin/env bash

#define parameters which are passed in.
APPLICATION_NAME=$1  # e.g. dluhc-epb-worker-integration
STAGE=$2 # i.e. [integration, staging, production]

cat << EOF
---
applications:
  - name: $APPLICATION_NAME
    memory: 512M
    instances: 1
    command: bundle exec sidekiq -r ./sidekiq/config.rb
    no-route: true
    buildpacks:
      - ruby_buildpack
    health-check-type: process
    services:
      - dluhc-epb-redis-sidekiq-$STAGE
      - dluhc-epb-db-$STAGE
EOF
