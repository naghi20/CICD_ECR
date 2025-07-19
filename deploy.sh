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

# ---- DEPLOY ECR ----
echo "Deploying ECR stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $ECR_STACK \
  --template-file infra/templates/ecs/ecr.yaml

#----PUSH IMAGE----
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
      VpcId=$(aws cloudformation describe-stacks --region $REGION --stack-name $VPC_STACK --query "Stacks[0].Outputs[?OutputKey=='VpcId'].OutputValue" --output text) \
      SubnetIds=$(aws cloudformation describe-stacks --region $REGION --stack-name $VPC_STACK --query "Stacks[0].Outputs[?OutputKey=='PublicSubnetIds'].OutputValue" --output text)

# ---- DEPLOY ECS SECURITY GROUPS ----
echo "Deploying ECS Security Groups stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $SG_STACK \
  --template-file infra/templates/ecs/security-groups.yaml \
  --parameter-overrides \
      VpcId=$(aws cloudformation describe-stacks --region $REGION --stack-name $VPC_STACK --query "Stacks[0].Outputs[?OutputKey=='VpcId'].OutputValue" --output text)

# ---- DEPLOY TASK DEFINITION ----
echo "Deploying ECS Task Definition stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $TASKDEF_STACK \
  --template-file infra/templates/ecs/taskdef.yaml \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
      ECRImageUri=$(aws cloudformation describe-stacks --region $REGION --stack-name $ECR_STACK --query "Stacks[0].Outputs[?OutputKey=='ECRRepoUri'].OutputValue" --output text):latest

# ---- DEPLOY ECS SERVICE ----
echo "Deploying ECS Service stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $SERVICE_STACK \
  --template-file infra/templates/ecs/service.yaml \
  --parameter-overrides \
      ClusterName=$(aws cloudformation describe-stacks --region $REGION --stack-name $CLUSTER_STACK --query "Stacks[0].Outputs[?OutputKey=='ClusterName'].OutputValue" --output text) \
      TaskDefinitionArn=$(aws cloudformation describe-stacks --region $REGION --stack-name $TASKDEF_STACK --query "Stacks[0].Outputs[?OutputKey=='TaskDefinitionArn'].OutputValue" --output text) \
      SubnetIds=$(aws cloudformation describe-stacks --region $REGION --stack-name $VPC_STACK --query "Stacks[0].Outputs[?OutputKey=='PublicSubnetIds'].OutputValue" --output text) \
      SecurityGroupId=$(aws cloudformation describe-stacks --region $REGION --stack-name $SG_STACK --query "Stacks[0].Outputs[?OutputKey=='ECSTaskSGId'].OutputValue" --output text) \
      TargetGroupArn=$(aws cloudformation describe-stacks --region $REGION --stack-name $ALB_STACK --query "Stacks[0].Outputs[?OutputKey=='TargetGroupArn'].OutputValue" --output text)

# ---- DEPLOY CODEBUILD ----
echo "Deploying CodeBuild stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $CODEBUILD_STACK \
  --template-file infra/templates/pipeline/codebuild.yaml \
  --parameter-overrides \
      GitHubRepo=$GITHUB_REPO \
      GitHubBranch=$GITHUB_BRANCH \
      ECRRepositoryUri=$(aws cloudformation describe-stacks --region $REGION --stack-name $ECR_STACK --query "Stacks[0].Outputs[?OutputKey=='ECRRepoUri'].OutputValue" --output text)

# ---- DEPLOY CODEPIPELINE ----
echo "Deploying CodePipeline stack..."
aws cloudformation deploy \
  --region $REGION \
  --stack-name $PIPELINE_STACK \
  --template-file infra/templates/pipeline/codepipeline.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      ClusterName=$(aws cloudformation describe-stacks --region $REGION --stack-name $CLUSTER_STACK --query "Stacks[0].Outputs[?OutputKey=='ClusterName'].OutputValue" --output text) \
      ServiceName=$(aws cloudformation describe-stacks --region $REGION --stack-name $SERVICE_STACK --query "Stacks[0].Outputs[?OutputKey=='ServiceName'].OutputValue" --output text)

echo "All stacks deployed successfully!"

# ---- PRINT USEFUL OUTPUTS ----
echo "ECS Service URL (ALB DNS):"
aws cloudformation describe-stacks --region $REGION --stack-name $ALB_STACK --query "Stacks[0].Outputs[?OutputKey=='ALBDNSName'].OutputValue" --output text
