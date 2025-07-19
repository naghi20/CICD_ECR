# Authenticate Docker to your ECR registry
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 225989367454.dkr.ecr.eu-west-2.amazonaws.com

# Build your Docker image (from your app directory)
docker build -t cicd-ecr-repo:latest ./app

# Tag the image for ECR
docker tag cicd-ecr-repo:latest 225989367454.dkr.ecr.eu-west-2.amazonaws.com/cicd-ecr-repo:latest

# Push the image to ECR
docker push 225989367454.dkr.ecr.eu-west-2.amazonaws.com/cicd-ecr-repo:latest