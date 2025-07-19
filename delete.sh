#!/bin/bash

# Usage: ./cleanup_stacks.sh stack1 stack2 stack3 ...
# Or edit STACKS array below with your stack names

STACKS=(
  "cicd-ecr-service"
  "cicd-ecr-taskdef"
  "cicd-ecr-cluster"
  "cicd-ecr-alb"
  "cicd-ecr-ecr"
  "cicd-ecr-logs"
  "cicd-ecr-sg"
  "cicd-vpc"
  "cicd-codebuild"
  "cicd-codepipeline"
)


for STACK in "${STACKS[@]}"; do
  echo "Deleting stack: $STACK"
  aws cloudformation delete-stack --stack-name "$STACK"
  echo "Waiting for stack $STACK to be deleted..."
  aws cloudformation wait stack-delete-complete --stack-name "$STACK"
  echo "Stack $STACK deleted."
done

echo "All specified stacks have been deleted."

