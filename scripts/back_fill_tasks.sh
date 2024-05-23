#!/bin/bash
# Usage

ENV=$1
VPC_NAME="epb-${ENV}-vpc"
SECURITY_GROUP_NAME="epb-${ENV}-scheduled-tasks-ecs-sg"
CLUSTER_NAME="epb-${ENV}-scheduled-tasks-cluster"
TASK="epb-${ENV}-scheduled-tasks-ecs-exec-cmd-task"
CONTAINER_NAME="epb-${ENV}-scheduled-tasks-container-db-migration"
DATE_START=""
DATE_END=""


VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=$VPC_NAME --query 'Vpcs[0].VpcId')

if [[ -z $VPC_ID  ]]; then
  echo "VPC NOT FOUND FOR PROFILE ${PROFILE}"
  exit 1
fi
SUBNET_GROUP_ID=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID --query 'Subnets[?MapPublicIpOnLaunch==`false`].SubnetId')

SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filter Name=group-name,Values=$SECURITY_GROUP_NAME --query 'SecurityGroups[0].GroupId' )

#echo ${VPC_NAME}
#echo ${VPC_ID}
#echo ${SUBNET_GROUP_ID}
#echo ${SECURITY_GROUP_ID}

JSON_STRING="{\"awsvpcConfiguration\": {\"subnets\": ${SUBNET_GROUP_ID}, \"securityGroups\": [${SECURITY_GROUP_ID}],\"assignPublicIp\":\"DISABLED\"}}"
CONATINER_OVERRIDES="{\"containerOverrides\": [ {\"name\": \"${CONTAINER_NAME}\",  \"cpu\": 1024, \"memory\" :4096, \"command\" : [\"bundle\", \"exec\", \"rake\",\"maintenance:backfill_country_ids\" ], \"environment\" : [ {\"name\" : \"DATE_FROM\", \"value\": \"2017-01-01\"}, {\"name\" : \"DATE_TO\", \"value\": \"2017-12-31\"}]}]}"

declare -a YEARS=(
 2008
 2009
 2010
 2011
 2012
 2013
 2014
 2015
 2016
 2018
 2020
)

for i in ${YEARS[@]}; do
  DATE_START="${i}-01-01"
  DATE_END="${i}-12-31"
   echo "-----"
   CONATINER_OVERRIDES="{\"containerOverrides\": [ {\"name\": \"${CONTAINER_NAME}\", \"command\" : [\"bundle\", \"exec\", \"rake\",\"maintenance:backfill_country_ids\" ], \"environment\" : [ {\"name\" : \"DATE_FROM\", \"value\": \"${DATE_START}\"}, {\"name\" : \"DATE_TO\", \"value\": \"${DATE_END}\"}]}]}"


   TASK_ID=$(aws ecs run-task  --cluster $CLUSTER_NAME  --task-definition $TASK  \
       --network-configuration "${JSON_STRING}" \
       --overrides "${CONATINER_OVERRIDES}" \
       --launch-type "FARGATE" --query 'tasks[0].containers[0].taskArn' | tr -d '"' )


   echo "PROVISIONING for ${i} - TASK ID: ${TASK_ID}"

done


exit 0
