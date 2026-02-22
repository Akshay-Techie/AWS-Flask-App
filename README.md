# Project-03: Complete CI/CD Pipeline — GitHub to EKS with AWS

A production-ready CI/CD pipeline that automates the entire deployment workflow
from code push to Kubernetes cluster with comprehensive logging and monitoring.

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Workflow](#architecture-workflow)
3. [Folder Structure](#folder-structure)
4. [Prerequisites](#prerequisites)
5. [Setup Instructions](#setup-instructions)
6. [Jenkins Pipeline](#jenkins-pipeline)
7. [Docker Build & ECR Push](#docker-build--ecr-push)
8. [EKS Deployment](#eks-deployment)
9. [CloudWatch & S3 Logging](#cloudwatch--s3-logging)
10. [Running the Pipeline](#running-the-pipeline)
11. [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

This project demonstrates a **complete CI/CD pipeline** that includes:

- **Application**: Flask-based web application with a modern animated UI
- **Containerization**: Docker containerization for cross-platform deployment
- **CI/CD Orchestration**: Jenkins pipeline automation on local Ubuntu VirtualBox VM
- **Container Registry**: AWS ECR for storing Docker images
- **Kubernetes**: AWS EKS (project03-cluster) for deployment and orchestration
- **Monitoring**: CloudWatch for real-time logging and monitoring
- **Log Storage**: S3 bucket for long-term log archival
- **Infrastructure**: Terraform for all AWS resource provisioning

**Tech Stack:**
- Python 3.11 + Flask
- Docker Engine
- Jenkins (Local VirtualBox Ubuntu VM)
- AWS ECR (Elastic Container Registry)
- AWS EKS (Elastic Kubernetes Service) — Kubernetes 1.35
- AWS CloudWatch (Logs & Monitoring)
- AWS S3 (Log Storage)
- Terraform (Infrastructure as Code)

---

## 🏗️ Architecture Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                   Dev-to-Production Pipeline                │
└─────────────────────────────────────────────────────────────┘

  1. Code Push to GitHub
         ↓
  2. Jenkins Pipeline Executes (Local VBox VM):
     • Fetch Code from GitHub
     • Build Docker Image
     • Push Image to ECR
         ↓
  3. Deploy to EKS (project03-cluster)
     • Apply K8s Manifests
     • Rolling Update Deployment
     • Load Balancer Service
         ↓
  4. Application Runs in EKS Pod (t3.micro node)
         ↓
  5. Control Plane Logs → CloudWatch
     Log Group: /aws/eks/project03-cluster/cluster
         ↓
  6. Export Logs → S3
     Bucket: logs-s3-bucket-346b2c13d375
         ↓
  7. Long-term Storage & Compliance
```

---

## 📁 Folder Structure

```
Project-03/
│
├── main.py                          # Flask application entry point
├── dockerfile                       # Docker image configuration
├── Jenkinsfile                      # Jenkins declarative pipeline
├── .gitignore                       # Git ignore rules
├── README.md                        # This file
│
├── templates/
│   └── index.html                  # Frontend HTML template with animations
│
├── k8s/                            # Kubernetes manifests
│   ├── deployment.yaml             # K8s deployment (1 replica, t3.micro safe)
│   ├── service.yaml                # K8s LoadBalancer service (port 80)
│   └── configmap.yaml              # K8s config for app settings
│
├── AWS-Resources/                  # Terraform infrastructure as code
│   ├── main.tf                     # Terraform providers (aws, random, tls)
│   ├── variables.tf                # AWS variables (region, AMI, etc.)
│   ├── eks-cluster.tf              # EKS cluster, OIDC, IAM roles, node group
│   ├── aws-s3.tf                   # S3 bucket with versioning + public access block
│   ├── terraform.tfvars            # (Secrets — in .gitignore)
│   ├── terraform.tfstate           # (State file — in .gitignore)
│   └── myfile.txt                  # Sample test file for S3
│
└── jenkins-config/                 # Jenkins helper scripts
    ├── scripts/
    │   ├── docker-build.sh        # Docker build script
    │   ├── ecr-push.sh            # ECR push script
    │   ├── eks-deploy.sh          # EKS deployment script
    │   └── cloudwatch-config.sh   # CloudWatch agent setup
    ├── JENKINS_GUIDE.md
    ├── PROJECT_STRUCTURE.md
    └── SETUP_GUIDE.md
```

---

## 📋 Prerequisites

### 1. Local Machine Requirements
- Git installed
- AWS CLI v2 configured with credentials
- Terraform v1.5+ installed
- Docker installed
- VirtualBox with Ubuntu VM (for Jenkins)
- kubectl installed

### 2. AWS Account Setup
- Active AWS account
- IAM User (TF-User) with permissions:
  - ECR (Elastic Container Registry)
  - EKS (Kubernetes cluster)
  - CloudWatch (Logs & Monitoring)
  - S3 (Storage)
  - IAM (for roles & policies)

### 3. Jenkins Setup (Local VBox Ubuntu VM)
- Jenkins running on `http://localhost:8080`
- Plugins installed:
  - Docker Pipeline
  - Amazon ECR
  - Kubernetes CLI
  - Git Server

### 4. Jenkins Credentials Required
```
AWS_ACCESS_KEY_ID      → Secret text → your AWS access key
AWS_SECRET_ACCESS_KEY  → Secret text → your AWS secret key
AWS_ACCOUNT_ID         → Secret text → your AWS account ID (793433927733)
```

---

## 🚀 Setup Instructions

### Step 1: Clone Repository

```bash
git clone https://github.com/Akshay-Techie/AWS-Flask-App.git
cd AWS-Flask-App
```

### Step 2: Deploy AWS Infrastructure with Terraform

```bash
cd AWS-Resources

# Initialize Terraform (downloads aws, random, tls providers)
terraform init

# Preview changes
terraform plan

# Apply — creates EKS cluster + S3 bucket + IAM roles
terraform apply -auto-approve

# Get outputs
terraform output
```

**Resources created by Terraform:**
```
✅ EKS Cluster        → project03-cluster (Kubernetes 1.35)
✅ Node Group         → 1x t3.micro (AL2023_x86_64_STANDARD)
✅ OIDC Provider      → for IAM Roles for Service Accounts
✅ IAM Roles          → eks-cluster-role + eks-node-role
✅ S3 Bucket          → logs-s3-bucket-xxxxx (versioning enabled)
✅ CloudWatch Logs    → /aws/eks/project03-cluster/cluster
```

### Step 3: Connect kubectl to EKS

```bash
aws eks update-kubeconfig \
  --name project03-cluster \
  --region ap-south-1

# verify
kubectl get nodes
```

### Step 4: Fix coredns for t3.micro (important)

```bash
# t3.micro has limited pod capacity
# scale coredns to 1 replica to free space for app pod
kubectl scale deployment coredns --replicas=1 -n kube-system

# verify node has space
kubectl get pods -A
```

---

## 🔧 Jenkins Pipeline

### Jenkinsfile Stages

```
Stage 1 → Checkout Code       (~1s)   pulls from GitHub
Stage 2 → Build Docker Image  (~17s)  builds Flask app image
Stage 3 → Push to ECR         (~12s)  pushes to AWS ECR
Stage 4 → Update kubeconfig   (~8s)   connects kubectl to EKS
Stage 5 → Deploy to EKS       (~1min) rolling update deployment
Stage 6 → Verify Deployment   (~4s)   checks pods + services
Stage 7 → View Logs           (~1s)   shows last 50 log lines
```

### Create Jenkins Pipeline Job

```
Jenkins Dashboard
→ New Item
→ Name: project03-pipeline
→ Type: Pipeline
→ Pipeline section:
   Definition: Pipeline script from SCM
   SCM: Git
   URL: https://github.com/Akshay-Techie/AWS-Flask-App.git
   Branch: */main
   Script Path: Jenkinsfile
→ Save → Build Now
```

---

## 🐳 Docker Build & ECR Push

### Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY main.py .
COPY templates/ templates/
RUN pip install flask
EXPOSE 5000
CMD ["python", "main.py"]
```

### Manual Build & Push

```bash
# build image
docker build -t project03-app .

# test locally
docker run -p 5000:5000 project03-app
# open http://localhost:5000

# login to ECR
aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS --password-stdin \
793433927733.dkr.ecr.ap-south-1.amazonaws.com

# tag and push
docker tag project03-app \
793433927733.dkr.ecr.ap-south-1.amazonaws.com/project03-app:v1

docker push \
793433927733.dkr.ecr.ap-south-1.amazonaws.com/project03-app:v1
```

---

## ☸️ EKS Deployment

### Key Configuration Notes

```yaml
# deployment.yaml — important settings for t3.micro
spec:
  replicas: 1              # keep 1 — t3.micro has limited pod capacity
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0          # don't create new pod before deleting old
      maxUnavailable: 1    # delete old pod first then create new
```

```yaml
# service.yaml — important fix
sessionAffinity: None      # ClientIP causes LoadBalancer error on AWS
```

### Deploy Manually

```bash
# apply all k8s manifests
kubectl apply -f k8s/

# check pods
kubectl get pods

# get Load Balancer URL
kubectl get svc project03-service

# access app
http://<EXTERNAL-IP>
```

### Common Pod Issues on t3.micro

```bash
# if pods are pending — node is full
kubectl get pods -A

# fix — scale down coredns
kubectl scale deployment coredns --replicas=1 -n kube-system

# check node capacity
kubectl describe node | grep -A 5 "Allocated resources"
```

---

## 📊 CloudWatch & S3 Logging

### CloudWatch Log Group

```
Log Group: /aws/eks/project03-cluster/cluster
Region: ap-south-1
Captures: api, audit, scheduler, controllerManager, authenticator logs
```

### Export Logs to S3

```bash
# add bucket policy first (one time setup)
aws s3api put-bucket-policy \
  --bucket logs-s3-bucket-346b2c13d375 \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "logs.ap-south-1.amazonaws.com" },
      "Action": ["s3:GetBucketAcl", "s3:PutObject"],
      "Resource": [
        "arn:aws:s3:::logs-s3-bucket-346b2c13d375",
        "arn:aws:s3:::logs-s3-bucket-346b2c13d375/*"
      ],
      "Condition": {
        "StringEquals": { "aws:SourceAccount": "793433927733" }
      }
    }]
  }'

# export logs
aws logs create-export-task \
  --log-group-name "/aws/eks/project03-cluster/cluster" \
  --from 0 \
  --to $(date +%s000) \
  --destination "logs-s3-bucket-346b2c13d375" \
  --destination-prefix "eks-logs" \
  --region ap-south-1

# verify export
aws logs describe-export-tasks --region ap-south-1
```

---

## ▶️ Running the Pipeline

### Automatic (after GitHub push):

```bash
git add .
git commit -m "your changes"
git push origin main
# Jenkins triggers automatically via GitHub hook
```

### Manual Trigger:

```
Jenkins → project03-pipeline → Build Now
```

---

## 🗑️ Cleanup (Important — avoid AWS charges)

```bash
# Step 1 — empty S3 bucket
aws s3 rm s3://logs-s3-bucket-346b2c13d375 --recursive

# Step 2 — delete ECR repository
aws ecr delete-repository \
  --repository-name project03-app \
  --force \
  --region ap-south-1

# Step 3 — destroy all Terraform resources
cd AWS-Resources
terraform destroy -auto-approve
```

> ⚠️ EKS control plane costs $0.10/hour (~$2.4/day). Always destroy when not practicing!

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Pods Pending | `kubectl scale deployment coredns --replicas=1 -n kube-system` |
| LoadBalancer Pending | Check pod is Running first, then wait 3-5 mins |
| sessionAffinity error | Change `ClientIP` to `None` in service.yaml |
| ECR push failed | Re-login: `aws ecr get-login-password \| docker login` |
| kubectl wrong context | `aws eks update-kubeconfig --name project03-cluster --region ap-south-1` |
| S3 delete error | Empty bucket first: `aws s3 rm s3://bucket --recursive` |
| Pipeline timeout | Increase `--timeout=10m` in Jenkinsfile Deploy stage |

---

## 🔐 Security

- S3 bucket versioning enabled ✅
- S3 public access blocked ✅
- EKS OIDC provider configured ✅
- CloudWatch audit logging enabled ✅
- AWS credentials stored in Jenkins credentials store ✅
- Sensitive files in .gitignore ✅

---

## 📞 Documentation

- [Jenkins Docs](https://www.jenkins.io/doc/)
- [AWS EKS](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [Kubernetes Docs](https://kubernetes.io/docs/)

---

## 👤 Author

**Akshay** — Future MLOps Architect 🚀

---

## 📅 Last Updated

February 23, 2026

---

**Happy Deploying! 🚀**