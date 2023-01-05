#!/usr/bin/env bash

#define parameters which are passed in.
STAGE=$1 # i.e. [integration, staging, production]

case "$STAGE" in
 production) INSTANCE_MIN_COUNT="3"
             INSTANCE_MAX_COUNT="10"
             ;;
 *) INSTANCE_MIN_COUNT="1"
    INSTANCE_MAX_COUNT="3"
    ;;
esac

cat << EOF
{
  "instance_min_count": $INSTANCE_MIN_COUNT,
  "instance_max_count": $INSTANCE_MAX_COUNT,
  "scaling_rules": [
    {
      "metric_type": "cpu",
      "breach_duration_secs": 90,
      "threshold": 50,
      "operator": "<",
      "cool_down_secs": 60,
      "adjustment": "-1"
    },
    {
      "metric_type": "cpu",
      "breach_duration_secs": 90,
      "threshold": 50,
      "operator": ">=",
      "cool_down_secs": 60,
      "adjustment": "+1"
    }
  ]
}
EOF
