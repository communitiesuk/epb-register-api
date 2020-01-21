#!/usr/bin/env bash

STATE="$(cf curl /v3/apps/`cf app --guid ${DEPLOY_APPNAME}`/tasks?order_by=-created_at | jq -r '.resources[0].state')"
echo "${STATE}"

while [[ ${STATE} = "RUNNING" ]]
do
	sleep 2
	STATE="$(cf curl /v3/apps/`cf app --guid ${DEPLOY_APPNAME}`/tasks?order_by=-created_at | jq -r '.resources[0].state')"
done

echo "Migration result is ${STATE}"
if [[ ${STATE} = "SUCCEEDED" ]] 
then
	exit 0
else
	exit 1
fi
