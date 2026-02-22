# Project-03: Complete CI/CD Pipeline — GitHub to EKS with AWS

A production-ready CI/CD pipeline that automates the entire deployment workflow from code push to Kubernetes cluster with comprehensive logging and monitoring.

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Workflow](#architecture-workflow)
3. [Folder Structure](#folder-structure)
4. [Prerequisites](#prerequisites)
5. [Setup Instructions](#setup-instructions)
6. [GitHub Configuration](#github-configuration)
7. [Jenkins Pipeline](#jenkins-pipeline)
8. [Docker Build & ECR Push](#docker-build--ecr-push)
9. [EKS Deployment](#eks-deployment)
10. [CloudWatch & S3 Logging](#cloudwatch--s3-logging)
11. [Running the Pipeline](#running-the-pipeline)
12. [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

This project demonstrates a **complete enterprise-grade CI/CD pipeline** that includes:

- **Application**: A Flask-based web application with a modern UI
- **Containerization**: Docker containerization for cross-platform deployment
- **CI/CD Orchestration**: Jenkins pipeline automation on Ubuntu VM
- **Container Registry**: AWS ECR for storing Docker images
- **Kubernetes**: AWS EKS for production deployment and orchestration
- **Monitoring**: CloudWatch for real-time logging and monitoring
- **Log Storage**: S3 bucket for long-term log archival and compliance

**Tech Stack:**
- Python 3.11 + Flask
- Docker Engine
- Jenkins (On-Premise, Ubuntu VM)
- AWS ECR (Elastic Container Registry)
- AWS EKS (Elastic Kubernetes Service)
- AWS CloudWatch (Logs & Monitoring)
- AWS S3 (Log Storage)
- Terraform (Infrastructure as Code)

---

## 🏗️ Architecture Workflow

```
┌──────────────────────────────────────────────────────────────┐
│                    Dev-to-Production Pipeline                │
└──────────────────────────────────────────────────────────────┘

  1. Code Push to GitHub
         ↓
  2. Webhook Triggers Jenkins Job
         ↓
  3. Jenkins Pipeline Executes:
     • Fetch Code from GitHub
     • Build Docker Image
     • Run Tests (optional)
     • Push Image to ECR
         ↓
  4. Deploy to EKS
     • Create K8s Deployment
     • Manage Pod Replicas
     • Load Balancing
         ↓
  5. Application Runs in EKS Pods
         ↓
  6. Logs Collected by CloudWatch Agent
         ↓
  7. Real-time Monitoring in CloudWatch Dashboard
         ↓
  8. Archive Logs to S3 (Daily/Weekly)
         ↓
  9. Long-term Storage & Compliance
```

---

## 📁 Folder Structure

```
Project-03/
│
├── main.py                          # Flask application main file
├── dockerfile                       # Docker image configuration
├── .gitignore                       # Git ignore rules
├── README.md                        # This file
│
├── templates/
│   └── index.html                  # Frontend HTML template (UI)
│
├── AWS-Resources/                  # Terraform infrastructure as code
│   ├── main.tf                     # Terraform providers & config
│   ├── variables.tf                # AWS variables (region, AMI, etc.)
│   ├── eks-cluster.tf              # EKS cluster, IAM roles, worker nodes
│   ├── aws-s3.tf                   # S3 bucket for CloudWatch logs
│   ├── terraform.tfvars            # (Secrets - in .gitignore)
│   ├── terraform.tfstate           # (State file - in .gitignore)
│   ├── terraform.tfstate.backup    # (State backup - in .gitignore)
│   └── myfile.txt                  # Sample test file
│
├── jenkins-config/                 # [TO CREATE] Jenkins pipeline config
│   ├── Jenkinsfile                 # Jenkins declarative pipeline
│   ├── scripts/
│   │   ├── docker-build.sh        # Docker build script
│   │   ├── ecr-push.sh            # ECR push script
│   │   ├── eks-deploy.sh          # EKS deployment script
│   │   └── cloudwatch-config.sh   # CloudWatch agent setup
│   └── k8s/
│       ├── deployment.yaml         # K8s deployment manifest
│       ├── service.yaml            # K8s service (Load Balancer)
│       └── configmap.yaml          # K8s config for app settings
│
└── docs/                           # [TO CREATE] Documentation
    ├── SETUP_GUIDE.md             # Step-by-step setup
    ├── JENKINS_GUIDE.md           # Jenkins configuration details
    └── TROUBLESHOOTING.md         # Common issues & fixes
```

---

## 📋 Prerequisites

### 1. **Local Machine Requirements**
- Git installed
- AWS CLI v2 configured with credentials
- Terraform v1.5+ installed
- Docker Desktop (for local testing)

### 2. **AWS Account Setup**
- Active AWS account with billing enabled
- IAM User with permissions:
  - EC2 (for Jenkins VM)
  - ECR (Elastic Container Registry)
  - EKS (Kubernetes cluster)
  - CloudWatch (Logs & Monitoring)
  - S3 (Storage)
  - IAM (for roles & policies)

### 3. **GitHub Setup**
- GitHub repository created
- Code pushed to `main` branch
- GitHub Personal Access Token (for Jenkins webhook)

### 4. **AWS Resources to Create Manually**
```bash
# 1. Create EC2 Key Pair (for SSH access to Jenkins)
aws ec2 create-key-pair --key-name project03-jenkins-key \
  --region ap-south-1 \
  --query 'KeyMaterial' --output text > project03-jenkins-key.pem
chmod 400 project03-jenkins-key.pem

# 2. Note your AWS Account ID (for ECR URI)
aws sts get-caller-identity --query Account --output text

# 3. Create IAM User for Jenkins (optional but recommended)
# This user will have permissions to push to ECR only
aws iam create-user --user-name jenkins-ecr-user
```

---

## 🚀 Setup Instructions

### Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/Project-03.git
cd Project-03
```

### Step 2: Configure Terraform Variables

Edit `AWS-Resources/terraform.tfvars`:

```hcl
region       = "ap-south-1"              # Change if needed
ami_id       = "ami-0e35ddab05955cf57"   # Ubuntu 22.04 (ap-south-1)
instance_type = "t3.micro"               # Jenkins server type
keypair_name  = "project03-jenkins-key"  # Your EC2 key pair
```

### Step 3: Deploy AWS Infrastructure with Terraform

```bash
cd AWS-Resources

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply to create AWS resources (EC2, EKS, S3)
terraform apply -auto-approve

# Get outputs (Jenkins IP, EKS cluster name, S3 bucket)
terraform output
```

**Terraform Outputs:**
```
jenkins_instance_ip = "54.XXX.XXX.XXX"
eks_cluster_name = "project03-cluster"
s3_bucket_name = "logs-s3-bucket-abc123xyz"
```

### Step 4: SSH into Jenkins VM

```bash
# SSH into Jenkins server
ssh -i project03-jenkins-key.pem ubuntu@<JENKINS_IP>

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Java (required for Jenkins)
sudo apt-get install -y openjdk-11-jdk

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Docker (for docker build commands in pipeline)
sudo apt-get install -y docker.io
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

# Install kubectl (to deploy to EKS)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI
sudo apt-get install -y awscli

# Verify installations
jenkins --version
docker --version
kubectl version --client
aws --version
```

### Step 5: Initial Jenkins Setup

```bash
# Get Jenkins initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Open Jenkins in browser
# http://<JENKINS_IP>:8080

# Login with password from above, then:
# 1. Install suggested plugins
# 2. Create first admin user
# 3. Configure Jenkins URL
```

### Step 6: Configure AWS Credentials in Jenkins

**Jenkins Dashboard → Manage Jenkins → Manage Credentials:**

1. Click **"New credentials"**
2. Kind: **"AWS Credentials"**
3. Access Key ID: (from IAM user)
4. Secret Access Key: (from IAM user)
5. ID: `aws-credentials`

**For Jenkins to Push to ECR:**
```bash
# Login to ECR repo on Jenkins VM
aws ecr get-login-password --region ap-south-1 | docker login \
  --username AWS \
  --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com
```

---

## 🔗 GitHub Configuration

### Create GitHub Webhook

**GitHub Repository → Settings → Webhooks:**

1. **Payload URL**: `http://<JENKINS_IP>:8080/github-webhook/`
2. **Content type**: `application/json`
3. **Events**: `Push events` ✓
4. **Active**: ✓

### Jenkins GitHub Plugin

**Jenkins Dashboard → Manage Jenkins → Manage Plugins:**
- Install: **GitHub plugin**
- Install: **GitHub Integration**

---

## 🔧 Jenkins Pipeline

### Create Jenkins Job (Declarative Pipeline)

**Jenkins Dashboard → New Item:**
- Name: `project03-pipeline`
- Type: **Pipeline**

### Jenkinsfile Content

Create `Jenkinsfile` in root directory:

```groovy
pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = credentials('AWS_ACCOUNT_ID')
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_REPO_NAME = 'project03-flask-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        EKS_CLUSTER_NAME = 'project03-cluster'
        K8S_NAMESPACE = 'default'
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo '===== Pulling code from GitHub ====='
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '===== Building Docker image ====='
                script {
                    sh '''
                        docker build -t ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} .
                        docker tag ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} \
                                  ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                echo '===== Pushing image to Amazon ECR ====='
                script {
                    sh '''
                        # Login to ECR
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        
                        # Create ECR repository if not exists
                        aws ecr describe-repositories \
                            --repository-names ${ECR_REPO_NAME} \
                            --region ${AWS_REGION} || \
                        aws ecr create-repository \
                            --repository-name ${ECR_REPO_NAME} \
                            --region ${AWS_REGION}
                        
                        # Push images
                        docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest
                    '''
                }
            }
        }

        stage('Update kubeconfig') {
            steps {
                echo '===== Configuring kubectl for EKS cluster ====='
                script {
                    sh '''
                        aws eks update-kubeconfig \
                            --name ${EKS_CLUSTER_NAME} \
                            --region ${AWS_REGION}
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo '===== Deploying to EKS cluster ====='
                script {
                    sh '''
                        # Create namespace if not exists
                        kubectl create namespace ${K8S_NAMESPACE} || true
                        
                        # Apply Kubernetes manifests
                        kubectl apply -f k8s/ -n ${K8S_NAMESPACE}
                        
                        # Update image in deployment
                        kubectl set image deployment/project03-app \
                            project03-app=${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} \
                            -n ${K8S_NAMESPACE} || true
                        
                        # Wait for rollout to complete
                        kubectl rollout status deployment/project03-app \
                            -n ${K8S_NAMESPACE} --timeout=5m
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '===== Verifying EKS Deployment ====='
                script {
                    sh '''
                        echo "Pods status:"
                        kubectl get pods -n ${K8S_NAMESPACE}
                        
                        echo "Services:"
                        kubectl get svc -n ${K8S_NAMESPACE}
                        
                        echo "Deployment status:"
                        kubectl describe deployment project03-app -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline executed successfully!'
            echo "Application deployed: ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo '❌ Pipeline failed! Check logs above.'
        }
        always {
            // Clean up
            deleteDir()
        }
    }
}
```

---

## 🐳 Docker Build & ECR Push

### Dockerfile Explanation

```dockerfile
# Use official lightweight Python image
FROM python:3.11-slim

# Set working directory inside container
WORKDIR /app

# Copy main.py into container
COPY main.py .

# Copy templates folder (contains index.html) into container
COPY templates/ templates/

# Install Flask
RUN pip install flask

# Expose port 5000
EXPOSE 5000

# Run the app
CMD ["python", "main.py"]
```

**Image Details:**
- **Base Image**: `python:3.11-slim` (~200MB)
- **Working Directory**: `/app`
- **Port**: 5000
- **Command**: Starts Flask app with `python main.py`

### Manual Docker Build & Push

```bash
# Set variables
AWS_REGION="ap-south-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPO_NAME="project03-flask-app"
IMAGE_TAG="1.0"

# Build Docker image locally
docker build -t ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} .

# Tag with 'latest'
docker tag ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} \
           ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Create ECR repository
aws ecr create-repository \
    --repository-name ${ECR_REPO_NAME} \
    --region ${AWS_REGION}

# Push image to ECR
docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest

# Verify in ECR
aws ecr describe-images --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}
```

---

## ☸️ EKS Deployment

### Kubernetes Manifests

Create `k8s/` folder with manifests:

**k8s/deployment.yaml**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: project03-app
  labels:
    app: project03
spec:
  replicas: 2
  selector:
    matchLabels:
      app: project03
  template:
    metadata:
      labels:
        app: project03
    spec:
      containers:
      - name: project03-app
        image: ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/project03-flask-app:latest
        ports:
        - containerPort: 5000
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
```

**k8s/service.yaml**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: project03-service
spec:
  type: LoadBalancer
  selector:
    app: project03
  ports:
  - port: 80
    targetPort: 5000
    protocol: TCP
  sessionAffinity: ClientIP
```

**k8s/configmap.yaml**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: project03-config
data:
  FLASK_ENV: production
  LOG_LEVEL: INFO
```

### Manual EKS Deployment

```bash
# Update kubeconfig
aws eks update-kubeconfig --name project03-cluster --region ap-south-1

# Create namespace
kubectl create namespace default

# Apply manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get deployments -n default
kubectl get pods -n default
kubectl get svc -n default

# Get Load Balancer URL
kubectl get svc project03-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Scale deployment
kubectl scale deployment project03-app --replicas=3 -n default

# View logs from pods
kubectl logs -f deployment/project03-app -n default
```

---

## 📊 CloudWatch & S3 Logging

### CloudWatch Agent Setup

**Install on EKS nodes** (Jenkins script or user data):

```bash
#!/bin/bash

# Download CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

# Install
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

# Create config file
cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json << EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/containers/*.log",
            "log_group_name": "/aws/eks/project03-cluster",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_USAGE_IDLE",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"],
        "totalcpu": false
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED_PERCENT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json
```

### CloudWatch Dashboard

**AWS Console → CloudWatch → Dashboards:**

```bash
# Create custom dashboard
aws cloudwatch put-dashboard --dashboard-name project03-dashboard --dashboard-body '{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/ECS", "CPUUtilization", { "stat": "Average" } ],
          [ ".", "MemoryUtilization", { "stat": "Average" } ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "ap-south-1",
        "title": "EKS Node Metrics"
      }
    }
  ]
}'
```

### S3 Log Export

**Export CloudWatch Logs to S3 (Lambda + EventBridge):**

```bash
# Manual export via CLI
aws logs create-export-task \
  --log-group-name "/aws/eks/project03-cluster" \
  --from $(date -d '24 hours ago' +%s)000 \
  --to $(date +%s)000 \
  --destination logs-s3-bucket-xxx \
  --destination-prefix "cloudwatch-logs/"

# Or create Lambda for daily exports
# See Terraform: AWS-Resources/s3-export-lambda.tf (to be created)
```

---

## ▶️ Running the Pipeline

### Method 1: GitHub Push (Automatic)

```bash
# Make changes to code
git add .
git commit -m "Feature: Add new endpoint"
git push origin main

# Jenkins automatically triggers via webhook
# Monitor at: http://<JENKINS_IP>:8080/job/project03-pipeline/
```

### Method 2: Manual Trigger in Jenkins

1. Jenkins Dashboard → `project03-pipeline` → **Build Now**
2. Monitor progress in **Console Output**
3. Check deployment: `kubectl get pods`

### Method 3: Jenkins CLI

```bash
# Install Jenkins CLI
java -jar jenkins-cli.jar -s http://<JENKINS_IP>:8080 help

# Trigger build
java -jar jenkins-cli.jar -s http://<JENKINS_IP>:8080 build project03-pipeline
```

### Pipeline Execution Flow

```
Code Push to GitHub
         ↓
GitHub Webhook → Jenkins
         ↓
Jenkins Job Starts (Stage 1: Checkout Code)
         ↓
Build Docker Image (Stage 2)
         ↓
Push to ECR (Stage 3)
         ↓
Update kubeconfig (Stage 4)
         ↓
Deploy to EKS (Stage 5)
         ↓
Verify Deployment (Stage 6)
         ↓
✅ SUCCESS - App running on Load Balancer URL
```

---

## 📈 Monitoring & Logs

### View Application Logs

```bash
# Tail logs from deployment
kubectl logs -f deployment/project03-app -n default

# Logs from specific pod
kubectl logs pod/project03-app-xxxxx -n default

# Logs from all pods
kubectl logs -f -l app=project03 -n default
```

### CloudWatch Logs

```bash
# View logs in CloudWatch
aws logs tail /aws/eks/project03-cluster --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name "/aws/eks/project03-cluster" \
  --filter-pattern "ERROR"
```

### S3 Logs Access

```bash
# List exported logs
aws s3 ls s3://logs-s3-bucket-xxx/cloudwatch-logs/

# Download log file
aws s3 cp s3://logs-s3-bucket-xxx/cloudwatch-logs/logs.gz . --region ap-south-1
gunzip logs.gz
```

---

## 🐛 Troubleshooting

### Jenkins Issues

| Problem | Solution |
|---------|----------|
| Jenkins won't start | `sudo systemctl status jenkins` → Check `/var/log/jenkins/jenkins.log` |
| GitHub webhook fails | Verify firewall, check Jenkins plugin versions, test payload in GitHub |
| No Docker in pipeline | Ensure Jenkins user is in docker group: `sudo usermod -aG docker jenkins` |
| AWS credentials not found | Add credentials in Jenkins → Manage Credentials with ID `aws-credentials` |

### ECR Push Failures

```bash
# ECR login expired?
aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Repository doesn't exist?
aws ecr create-repository --repository-name project03-flask-app \
  --region ap-south-1

# Insufficient permissions?
# Verify IAM user has: `ecr:*` and `docker:*` permissions
```

### EKS Deployment Issues

```bash
# Pods stuck in pending?
kubectl describe pod <POD_NAME> -n default
kubectl get events -n default

# Image not found in ECR?
kubectl describe deployment project03-app -n default
# Check Status → ImagePullBackOff

# Node issues?
kubectl get nodes
kubectl describe node <NODE_NAME>

# Clear old deployments
kubectl delete deployment project03-app -n default
kubectl apply -f k8s/deployment.yaml -n default
```

### Terraform Errors

```bash
# State lock issue
terraform force-unlock LOCK_ID

# Provider version mismatch
terraform init -upgrade

# Variable validation failed
# Check terraform.tfvars matches variable types in variables.tf
```

---

## 🔐 Security Best Practices

1. **Secrets Management**
   - Use AWS Secrets Manager for API keys
   - Never commit `.env` files
   - Rotate IAM credentials regularly

2. **IAM Permissions**
   - Create separate Jenkins IAM user with ECR-only permissions
   - Use IAM roles for EKS nodes (no static credentials)

3. **ECR Security**
   - Enable image scanning
   - Use image signing (cosign)
   - Apply resource-based policies

4. **EKS Security**
   - Enable audit logging
   - Use network policies
   - Implement RBAC

5. **S3 Bucket**
   - Enable versioning ✓ (already done)
   - Block public access ✓ (already done)
   - Enable encryption
   - Set lifecycle policies for log retention

---

## 📞 Support & Documentation

- **Jenkins Docs**: https://www.jenkins.io/doc/
- **AWS EKS**: https://docs.aws.amazon.com/eks/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **Docker Docs**: https://docs.docker.com/

---

## 🎓 Learning Resources

- [Jenkins Pipeline Tutorial](https://www.jenkins.io/doc/book/pipeline/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS EKS Module](https://github.com/terraform-aws-modules/terraform-aws-eks)
- [CI/CD Patterns](https://martinfowler.com/articles/continuous-integration.html)

---

## 📝 License

This project is licensed under the MIT License — see LICENSE file for details.

---

## 👤 Author

**Akshay** - MLOps Architect  
Portfolio: [Your Portfolio URL]

---

## 📅 Last Updated

February 22, 2026

---

**Happy Deploying! 🚀**
