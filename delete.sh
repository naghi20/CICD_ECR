#!/bin/bash

# Usage: ./cleanup_stacks.sh stack1 stack2 stack3 ...
# Or edit STACKS array below with your stack names

STACKS=(
  "my-ecs-service-stack"
  "my-ecs-taskdef-stack"
  "my-ecs-cluster-stack"
  "my-alb-stack"
  "my-ecr-stack"
  "my-logs-stack"
  "my-security-groups-stack"
  "my-vpc-stack"
  "my-codebuild-stack"
  "my-codepipeline-stack"
)


for STACK in "${STACKS[@]}"; do
  echo "Deleting stack: $STACK"
  aws cloudformation delete-stack --stack-name "$STACK"
  echo "Waiting for stack $STACK to be deleted..."
  aws cloudformation wait stack-delete-complete --stack-name "$STACK"
  echo "Stack $STACK deleted."
done

echo "All specified stacks have been deleted."

