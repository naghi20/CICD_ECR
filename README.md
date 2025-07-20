# CICD_ECR: Automated CI/CD Pipeline for AWS ECS/Fargate

This project provides a **modular, production-ready CI/CD pipeline** for containerized applications on AWS, using **ECS (Fargate)**, **ECR**, **CodePipeline**, and **CloudFormation**.  
It includes all infrastructure as code (IaC) templates, application code, Dockerization, and automated testing.

---

## 🚀 Features

- **Infrastructure as Code:** Modular CloudFormation templates for VPC, ECS, ECR, ALB, IAM, and more.
- **CI/CD Pipeline:** Automated build, test, and deploy using AWS CodePipeline and CodeBuild.
- **Containerized App:** Example Flask app with Dockerfile and tests.
- **Cross-Stack References:** All outputs/exports wired for multi-stack deployments.
- **Best Practices:** Secure IAM roles, logging, and high-availability networking.

---

## 🗂️ Repository Structure
CICD_ECR/

├── app/                       # Application source code & tests

│   ├── app.py

│   └── test_app.py

├── buildspec.yml              # CodeBuild build/test/push spec

├── requirements.txt           # Python dependencies (Flask, pytest, etc.)

├── dockerfile                 # Dockerfile for the app

└── infra/

    └── templates/
    
        ├── vpc/               # VPC, subnets, security groups
        
        │   └── vpc.yaml
        
        ├── ecs/               # ECS cluster, service, taskdef, ECR, logs, ALB
        
        │   ├── cluster.yaml
        
        │   ├── service.yaml
        
        │   ├── taskdef.yaml

        │   ├── ecr.yaml
        
        │   ├── alb.yaml
        
        │   ├── security-groups.yaml
        
        │   └── logs.yaml
        
        └── pipeline/
        
            ├── codepipeline.yaml
            
            └── codebuild.yaml
            
          
---

## 🏗️ Prerequisites

- AWS CLI configured with admin permissions
- [AWS CloudFormation](https://aws.amazon.com/cloudformation/)
- [Docker](https://www.docker.com/)
- [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (for pipeline source)
- S3 bucket for pipeline artifacts (e.g., `cicd-ecr-artifacts`)
- Python 3.9+ (for local testing)

---

## ⚡ Quick Start

### 1. **Clone the Repository**
git clone https://github.com/naghi20/CICD_ECR.git
cd CICD_ECR


---

### 2. **Deploy Infrastructure (CloudFormation)**

Deploy each stack in order, passing outputs as parameters to dependent stacks.  
You can use the provided [deploy.sh](#-deployment-helper-script) or run manually each template:

## 📝 Deployment Helper Script

You can automate stack creation with a bash script.  
 chmode +x deploy.sh                            (file:///CICD_ECR/deploy.sh)**
 ./deploy.sh 
---

### 3. **Configure GitHub and AWS Secrets**

- Add your GitHub Personal Access Token to AWS Secrets Manager (for CodePipeline source).
- Set up any required [GitHub Actions secrets](https://github.com/naghi20/CICD_ECR/settings/secrets/actions) if using GitHub Actions.

---

### 4. **Push Code and Trigger Pipeline**

- Commit and push your code to the `main` branch.
- The pipeline will automatically build, test, and deploy your app to ECS Fargate.

---

## 🧪 Local Development & Testing

### Build and Test Locally
cd app
pip install -r requirements.txt
pytest
docker build -t cicd-ecr-app .
docker run -p 80:80 cicd-ecr-app




---

## 🛠️ Customization

- **App code:** Edit files in [`app/`](file:///CICD_ECR/app/)
- **Dockerfile:** Update as needed for your app’s requirements.
- **CloudFormation:** Adjust parameters, resource names, and outputs in [`infra/templates/`](file:///CICD_ECR/infra/templates/)
- **Pipeline:** Edit [`buildspec.yml`](file:///CICD_ECR/buildspec.yml) and [`codepipeline.yaml`](file:///CICD_ECR/infra/templates/pipeline/codepipeline.yaml) for custom build/test/deploy logic.

---

## 📚 References

- [AWS ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)
- [AWS CodePipeline User Guide](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)
- [AWS CloudFormation Cross-Stack References](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html)
- [Managing your personal access tokens - GitHub Docs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)

---

## 📝 License

MIT License. See [LICENSE](LICENSE) for details.

---

## 🙋‍♂️ Support

For questions or issues, open an [issue](https://github.com/naghi20/CICD_ECR/issues) or contact the maintainer.

