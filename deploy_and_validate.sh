#!/bin/bash
set -e

# ---- CONFIGURATION ----
REGION="eu-west-2"
VPC_STACK="cicd-ecr-vpc"
ECR_STACK="cicd-ecr-ecr"
LOGS_STACK="cicd-ecr-logs"
CLUSTER_STACK="cicd-ecr-cluster"
ALB_STACK="cicd-ecr-alb"
SG_STACK="cicd-ecr-sg"
TASKDEF_STACK="cicd-ecr-taskdef"
SERVICE_STACK="cicd-ecr-service"
CODEBUILD_STACK="cicd-ecr-codebuild"
PIPELINE_STACK="cicd-ecr-pipeline"

GITHUB_REPO="naghi20/CICD_ECR"
GITHUB_BRANCH="main"

# ---- DEPLOY VPC ----
echo "Deploying VPC stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $VPC_STACK \
  --template-file infra/templates/vpc/vpc.yaml \
  --capabilities CAPABILITY_NAMED_IAM

# ---- VALIDATE VPC OUTPUTS ----
VPC_ID=$(aws cloudformation describe-stacks --region $REGION --stack-name $VPC_STACK --query "Stacks[0].Outputs[?OutputKey=='VpcId'].OutputValue" --output text)
PUBLIC_SUBNET_IDS=$(aws cloudformation describe-stacks --region $REGION --stack-name $VPC_STACK --query "Stacks[0].Outputs[?OutputKey=='PublicSubnetIds'].OutputValue" --output text)
APP_SG=$(aws cloudformation describe-stacks --region $REGION --stack-name $VPC_STACK --query "Stacks[0].Outputs[?OutputKey=='AppSecurityGroup'].OutputValue" --output text)

if [[ -z "$VPC_ID" || -z "$PUBLIC_SUBNET_IDS" || -z "$APP_SG" ]]; then
  echo "ERROR: VPC stack outputs missing. Check your template and deployment."
  exit 1
fi

# ---- DEPLOY ECR ----
echo "Deploying ECR stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $ECR_STACK \
  --template-file infra/templates/ecs/ecr.yaml

# ---- VALIDATE ECR OUTPUT ----
ECR_URI=$(aws cloudformation describe-stacks --region $REGION --stack-name $ECR_STACK --query "Stacks[0].Outputs[?OutputKey=='ECRRepoUri'].OutputValue" --output text)
if [[ -z "$ECR_URI" ]]; then
  echo "ERROR: ECR stack output missing."
  exit 1
fi

# ---- PUSH IMAGE ----
echo "Building and pushing Docker image..."
. app/push.sh

# ---- DEPLOY LOGS ----
echo "Deploying CloudWatch Logs stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $LOGS_STACK \
  --template-file infra/templates/ecs/logs.yaml

# ---- DEPLOY ECS CLUSTER ----
echo "Deploying ECS Cluster stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $CLUSTER_STACK \
  --template-file infra/templates/ecs/cluster.yaml

# ---- DEPLOY ALB ----
echo "Deploying ALB stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $ALB_STACK \
  --template-file infra/templates/ecs/alb.yaml \
  --parameter-overrides \
      VpcId=$VPC_ID \
      SubnetIds=$PUBLIC_SUBNET_IDS

# ---- VALIDATE ALB OUTPUTS ----
ALB_DNS=$(aws cloudformation describe-stacks --region $REGION --stack-name $ALB_STACK --query "Stacks[0].Outputs[?OutputKey=='ALBDNSName'].OutputValue" --output text)
TG_ARN=$(aws cloudformation describe-stacks --region $REGION --stack-name $ALB_STACK --query "Stacks[0].Outputs[?OutputKey=='TargetGroupArn'].OutputValue" --output text)
ALB_SG=$(aws cloudformation describe-stacks --region $REGION --stack-name $ALB_STACK --query "Stacks[0].Outputs[?OutputKey=='ALBSecurityGroupId'].OutputValue" --output text)

if [[ -z "$ALB_DNS" || -z "$TG_ARN" || -z "$ALB_SG" ]]; then
  echo "ERROR: ALB stack outputs missing."
  exit 1
fi

# ---- DEPLOY ECS SECURITY GROUPS ----
echo "Deploying ECS Security Groups stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $SG_STACK \
  --template-file infra/templates/ecs/security-groups.yaml \
  --parameter-overrides \
      VpcId=$VPC_ID

# ---- VALIDATE SG OUTPUT ----
TASK_SG=$(aws cloudformation describe-stacks --region $REGION --stack-name $SG_STACK --query "Stacks[0].Outputs[?OutputKey=='ECSTaskSGId'].OutputValue" --output text)
if [[ -z "$TASK_SG" ]]; then
  echo "ERROR: ECS Security Group output missing."
  exit 1
fi

# ---- DEPLOY TASK DEFINITION ----
echo "Deploying ECS Task Definition stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $TASKDEF_STACK \
  --template-file infra/templates/ecs/taskdef.yaml \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
      ECRImageUri=${ECR_URI}:latest

# ---- VALIDATE TASKDEF OUTPUT ----
TASKDEF_ARN=$(aws cloudformation describe-stacks --region $REGION --stack-name $TASKDEF_STACK --query "Stacks[0].Outputs[?OutputKey=='TaskDefinitionArn'].OutputValue" --output text)
if [[ -z "$TASKDEF_ARN" ]]; then
  echo "ERROR: Task Definition output missing."
  exit 1
fi

# ---- DEPLOY ECS SERVICE ----
echo "Deploying ECS Service stack..."
CLUSTER_NAME=$(aws cloudformation describe-stacks --region $REGION --stack-name $CLUSTER_STACK --query "Stacks[0].Outputs[?OutputKey=='ClusterName'].OutputValue" --output text)
aws cloudformation deploy \
  --region $REGION \
  --stack-name $SERVICE_STACK \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-file infra/templates/ecs/service.yaml \
  --parameter-overrides \
      ClusterName=$CLUSTER_NAME \
      TaskDefinitionArn=$TASKDEF_ARN \
      SubnetIds=$PUBLIC_SUBNET_IDS \
      SecurityGroupId=$TASK_SG \
      TargetGroupArn=$TG_ARN

# ---- VALIDATE SERVICE OUTPUT ----
SERVICE_NAME=$(aws cloudformation describe-stacks --region $REGION --stack-name $SERVICE_STACK --query "Stacks[0].Outputs[?OutputKey=='ServiceName'].OutputValue" --output text)
if [[ -z "$SERVICE_NAME" ]]; then
  echo "ERROR: ECS Service output missing."
  exit 1
fi

# ---- DEPLOY CODEBUILD ----
echo "Deploying CodeBuild stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $CODEBUILD_STACK \
  --template-file infra/templates/pipeline/codebuild.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      GitHubRepo=$GITHUB_REPO \
      GitHubBranch=$GITHUB_BRANCH \
      ECRRepositoryUri=$ECR_URI

# ---- DEPLOY CODEPIPELINE ----
echo "Deploying CodePipeline stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $PIPELINE_STACK \
  --template-file infra/templates/pipeline/codepipeline.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      ClusterName=$CLUSTER_NAME \
      ServiceName=$SERVICE_NAME

echo "All stacks deployed successfully!"

# ---- PRINT USEFUL OUTPUTS ----
echo "ECS Service URL (ALB DNS): $ALB_DNS"
echo "Validate your deployment by visiting: http://$ALB_DNS/"
