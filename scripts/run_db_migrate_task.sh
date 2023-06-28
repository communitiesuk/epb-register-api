#!/bin/bash
# Usage
#
# ./run_db_migrate_task.sh $CLIENT_ROLE_ARN client
PREFIX=$1
PROFILE=$2
VPC_NAME="${PREFIX}-vpc"
SECURITY_GROUP_NAME="${PREFIX}-reg-api-ecs-sg"
CLUSTER_NAME="${PREFIX}-reg-api-cluster"
TASK="${PREFIX}-reg-api-ecs-exec-cmd-task"

VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=$VPC_NAME --query 'Vpcs[0].VpcId' --profile $PROFILE)

if [[ $VPC_ID = "" ]]; then
  echo "VPC NOT FOUND FOR PROFILE ${PROFILE}"
  exit 1
fi

SUBNET_GROUP_ID=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID --query 'Subnets[?MapPublicIpOnLaunch==`false`].SubnetId' --profile $PROFILE)

SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filter Name=group-name,Values=$SECURITY_GROUP_NAME --query 'SecurityGroups[0].GroupId' --profile $PROFILE )

JSON_STRING="{\"awsvpcConfiguration\": {\"subnets\": ${SUBNET_GROUP_ID}, \"securityGroups\": [${SECURITY_GROUP_ID}],\"assignPublicIp\":\"DISABLED\"}}"

TASK_ID=$(aws ecs run-task  --cluster $CLUSTER_NAME  --task-definition $TASK  \
    --network-configuration "${JSON_STRING}" \
    --launch-type "FARGATE" --query 'tasks[0].containers[0].taskArn' --profile $PROFILE | tr -d '"' )

STATUS=""

while [[ $STATUS != "\"STOPPED\"" ]]; do
STATUS=$(aws ecs describe-tasks  --cluster $CLUSTER_NAME --tasks $TASK_ID --query 'tasks[0].containers[0].lastStatus' --profile $PROFILE)
echo "${STATUS} << WAITING FOR MIGRATION TASK TO COMPLETE"

sleep 5
done

EXIT_CODE=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ID --query 'tasks[0].containers[0].exitCode' --profile $PROFILE)
if [[ $EXIT_CODE = 0 ]]; then
  echo "${TASK_ID} << MIGRATION TASK COMPLETED"
  exit 0
fi

echo 'MIGRATION TASK FAILED'
exit 1




