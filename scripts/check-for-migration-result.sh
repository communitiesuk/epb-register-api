#!/usr/bin/env bash

while [[ $(make cf-check-api-db-migration-task) = "RUNNING" ]]
do
	sleep 2
done

if [[ $(make cf-check-api-db-migration-task) = "SUCCEEDED" ]] 
then
	echo "Migration succeeded"
	exit 0
else
	echo "Migration result is $(make cf-check-api-db-migration-task)"
	exit 1
fi
