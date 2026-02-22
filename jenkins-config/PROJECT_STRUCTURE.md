# Project-03 Complete Folder Structure & Files Guide

## 📂 Final Project Structure

```
Project-03/
│
├── 📄 README.md                              ⭐ START HERE - Complete CI/CD documentation
├── 📄 Jenkinsfile                            ⭐ Jenkins declarative pipeline (auto-triggered)
├── 📄 dockerfile                             ⭐ Docker image configuration
├── 📄 main.py                                ⭐ Flask application main file
├── 📄 .gitignore                             Git ignore rules
│
├── 📁 templates/
│   └── 📄 index.html                         Frontend HTML (portfolio page)
│
├── 📁 AWS-Resources/                         🚀 Infrastructure as Code (Terraform)
│   ├── 📄 main.tf                            Terraform providers configuration
│   ├── 📄 variables.tf                       Terraform variables (region, AMI, etc)
│   ├── 📄 eks-cluster.tf                     EKS cluster setup (IAM, nodes, VPC)
│   ├── 📄 aws-s3.tf                          S3 bucket for log storage
│   ├── 📄 terraform.tfvars                   🔐 Variables (in .gitignore)
│   ├── 📄 terraform.tfstate                  🔐 State file (in .gitignore)
│   ├── 📄 terraform.tfstate.backup           🔐 State backup (in .gitignore)
│   └── 📄 myfile.txt                         Test file for S3 demo
│
├── 📁 jenkins-config/                        📝 Jenkins configuration & helpers
│   ├── 📄 JENKINS_GUIDE.md                   Complete Jenkins setup instructions
│   ├── 📄 SETUP_GUIDE.md                     End-to-end setup checklist
│   │
│   ├── 📁 scripts/                           🔧 Helper shell scripts
│   │   ├── 📄 docker-build.sh                Build Docker image locally
│   │   ├── 📄 ecr-push.sh                    Push image to AWS ECR
│   │   ├── 📄 eks-deploy.sh                  Deploy to EKS cluster
│   │   └── 📄 cloudwatch-config.sh          Setup CloudWatch monitoring
│   │
│   └── 📁 k8s/ [SYMLINK TO ../../k8s/]      Kubernetes manifests location
│       ├── 📄 deployment.yaml                K8s deployment config
│       ├── 📄 service.yaml                   LoadBalancer service
│       └── 📄 configmap.yaml                 Application configuration
│
└── 📁 k8s/                                   ☸️ Kubernetes manifests
    ├── 📄 deployment.yaml                    ⭐ EKS deployment (2 replicas, health checks)
    ├── 📄 service.yaml                       ⭐ LoadBalancer service (80:5000)
    └── 📄 configmap.yaml                     ⭐ App config (env variables)
```

---

## 📋 File Descriptions

### Root Level Files

| File | Purpose | Size | Edited |
|------|---------|------|--------|
| `README.md` | Complete project documentation | 25KB | ✅ New |
| `Jenkinsfile` | Jenkins CI/CD pipeline definition | 8KB | ✅ New |
| `dockerfile` | Docker image configuration | 300B | Existing |
| `main.py` | Flask web application | 250B | Existing |
| `.gitignore` | Git ignore rules | 200B | Existing |

---

### 📁 AWS-Resources/ (Terraform - Infrastructure)

| File | Purpose | Details |
|------|---------|---------|
| `main.tf` | Terraform providers | AWS, Random, TLS providers v6.33.0, v3.7.2, v4.0 |
| `variables.tf` | Input variables | region, ami_id, instance_type, keypair_name |
| `eks-cluster.tf` | EKS cluster setup | IAM roles, node groups, networking |
| `aws-s3.tf` | S3 bucket | Log storage with versioning & encryption |
| `terraform.tfvars` | Variable values | 🔐 IN .GITIGNORE - Never commit |
| `terraform.tfstate` | Terraform state | 🔐 IN .GITIGNORE - Local state backup |

**Key Resources Created:**
- ✅ EC2 Security Group (Jenkins VM)
- ✅ EC2 Instance (t3.micro, Ubuntu 22.04)
- ✅ EKS Cluster (project03-cluster)
- ✅ EKS Node Group (auto-scaling)
- ✅ S3 Bucket (logs storage)
- ✅ IAM Roles (EKS control plane, worker nodes)
- ✅ VPC & Networking

---

### 📁 templates/ (Frontend)

| File | Purpose | Lines |
|------|---------|-------|
| `index.html` | Portfolio webpage | 226 lines |

**Features:**
- Modern responsive design
- Animated gradient background
- Portfolio showcase
- Contact information
- Served by Flask at `/`

---

### 📁 jenkins-config/ (Jenkins & Deployment)

#### 📄 JENKINS_GUIDE.md
Complete Jenkins configuration documentation:
- Initial plugin setup
- GitHub integration
- Credentials management
- Pipeline troubleshooting
- Security best practices

#### 📄 SETUP_GUIDE.md
10-phase end-to-end setup:
- **Phase 1**: Local setup (30 min)
- **Phase 2**: AWS infrastructure (45-60 min)
- **Phase 3**: Jenkins server (1.5 hours)
- **Phase 4**: GitHub integration (20 min)
- **Phase 5**: Jenkins job setup (30 min)
- **Phase 6**: Pipeline testing (20 min)
- **Phase 7**: GitHub webhook testing (10 min)
- **Phase 8**: CloudWatch setup (30 min)
- **Phase 9**: S3 log archival (20 min)
- **Phase 10**: Security hardening (30 min)

#### 📁 scripts/ (Helper Scripts)

| Script | Purpose | Usage |
|--------|---------|-------|
| `docker-build.sh` | Build Docker image | `./docker-build.sh 1.0` |
| `ecr-push.sh` | Push to ECR registry | `./ecr-push.sh 1.0` |
| `eks-deploy.sh` | Deploy to EKS | `./eks-deploy.sh 1.0 default` |
| `cloudwatch-config.sh` | Setup CloudWatch agent | `sudo ./cloudwatch-config.sh install` |

**Features:**
- Color-coded output (success/error/info)
- Error handling with detailed messages
- Built-in validation checks
- Helpful troubleshooting hints
- Useful command suggestions

---

### 📁 k8s/ (Kubernetes Manifests)

#### 📄 deployment.yaml
**EKS Kubernetes Deployment**

```yaml
Replicas:              2 pods
Strategy:              RollingUpdate
Resources:             256Mi request, 512Mi limit
Health Checks:         Liveness & Readiness probes
Security:              Non-root user, drop capabilities
Affinity:              Pod anti-affinity (spread across nodes)
```

**Probes:**
- Liveness: Restart if unhealthy (30s initial delay, 10s period)
- Readiness: Remove from load balancer if unready (5s initial delay, 5s period)

**Resource Limits:**
- **Requests**: 100m CPU, 256Mi RAM (guaranteed)
- **Limits**: 500m CPU, 512Mi RAM (max allowed)

#### 📄 service.yaml
**LoadBalancer Service**

```yaml
Type:                  LoadBalancer (AWS NLB)
Port Mapping:          80:5000 (HTTP to Flask)
Session Affinity:      ClientIP (10800s timeout)
External Traffic:      Local (direct node routing)
```

**Generates:**
- Public AWS LoadBalancer URL
- Accessible from internet (port 80)
- Routes to Flask app (port 5000)

#### 📄 configmap.yaml
**Application Configuration**

```yaml
FLASK_ENV:             production
LOG_LEVEL:             INFO
DEBUG:                 False
WORKERS:               4
METRICS_ENABLED:       true
HEALTH_CHECK_ENABLED:  true
```

Mount location: Passed as environment variables to pods

---

## 🔄 CI/CD Pipeline Flow

```
1. DEVELOPER ACTION
   └─→ git push to GitHub main branch
       └─→ GitHub webhook triggers Jenkins

2. JENKINS PIPELINE
   ├─→ Stage 1: Checkout Code
   │   └─→ Clone repo from GitHub
   │
   ├─→ Stage 2: Build Docker Image
   │   └─→ docker build -t registry/image:tag .
   │
   ├─→ Stage 3: Push to ECR
   │   ├─→ aws ecr get-login-password
   │   ├─→ docker login
   │   └─→ docker push
   │
   ├─→ Stage 4: Update kubeconfig
   │   └─→ aws eks update-kubeconfig
   │
   ├─→ Stage 5: Deploy to EKS
   │   ├─→ kubectl create namespace
   │   ├─→ kubectl apply -f k8s/
   │   ├─→ kubectl set image (update with new tag)
   │   └─→ kubectl rollout status (wait for pods)
   │
   ├─→ Stage 6: Verify Deployment
   │   ├─→ kubectl get pods
   │   ├─→ kubectl get svc
   │   └─→ kubectl describe deployment
   │
   └─→ Stage 7: View Logs
       └─→ kubectl logs -f deployment/project03-app

3. MONITORING & LOGGING
   ├─→ CloudWatch Agent collects logs
   ├─→ Logs visible in CloudWatch console
   └─→ Daily export to S3

4. APPLICATION RUNNING
   └─→ Accessible at LoadBalancer URL (port 80)
```

---

## 📊 Key Statistics

| Metric | Value |
|--------|-------|
| Total Files | 21 |
| Documentation Files | 4 (README, SETUP_GUIDE, JENKINS_GUIDE, this file) |
| Code Files | 10 (Python, Dockerfile, HTML, Terraform, YAML) |
| Script Files | 4 (Shell helpers) |
| Configuration Files | 3 (.gitignore, Jenkinsfile, terraform.tfvars) |
| Total Lines of Code | ~3,000+ |
| Total Documentation | ~15,000+ lines |

---

## 🚀 Quick Start Commands

### Local Setup
```bash
cd Project-03
git add .
git commit -m "Initial setup"
git push origin main
```

### Deploy Infrastructure
```bash
cd AWS-Resources
terraform init
terraform apply
```

### SSH into Jenkins
```bash
ssh -i project03-jenkins-key.pem ubuntu://<JENKINS_IP>
```

### Deploy from Jenkins UI
```
1. Jenkins Dashboard → project03-pipeline → Build Now
2. Monitor Console Output
3. Total time: 6-10 minutes
4. Access app: http://<LOAD_BALANCER_URL>
```

### Deploy Manually
```bash
# Build
./jenkins-config/scripts/docker-build.sh 1.0

# Push
./jenkins-config/scripts/ecr-push.sh 1.0

# Deploy
./jenkins-config/scripts/eks-deploy.sh 1.0 default
```

---

## 🔐 Security Considerations

### Secrets Management
- ✅ `terraform.tfvars` in `.gitignore` 
- ✅ `terraform.tfstate` in `.gitignore`
- ✅ AWS credentials in Jenkins Credentials Store (not committed)
- ✅ GitHub token in Jenkins (not committed)

### IAM Best Practices
- ✅ Separate IAM user for Jenkins (ECR-only permissions)
- ✅ EKS nodes use IAM roles (no static credentials)
- ✅ Principle of least privilege applied

### Network Security
- ✅ EKS nodes in private subnets
- ✅ LoadBalancer provides public access
- ✅ Security groups restrict inbound traffic
- ✅ Jenkins accessible via SSH (key-based auth)

### Data Protection
- ✅ S3 bucket encryption enabled
- ✅ S3 public access blocked
- ✅ S3 versioning enabled (can recover old logs)
- ✅ CloudWatch logs encrypted

---

## 📈 Scaling & Future Enhancements

### Immediate Improvements
- [ ] Add Kubernetes RBAC policies
- [ ] Implement pod network policies
- [ ] Setup Prometheus + Grafana monitoring
- [ ] Add Helm charts for deployment
- [ ] Implement GitOps with ArgoCD

### Production Upgrades
- [ ] Multi-region deployment
- [ ] Auto-scaling policies (HPA)
- [ ] Database integration (RDS)
- [ ] API Gateway + WAF
- [ ] VPC peering for on-prem

### DevOps Enhancements
- [ ] Vault for secrets management
- [ ] Terraform Cloud/Enterprise
- [ ] SonarQube for code quality
- [ ] Artifactory for artifact storage
- [ ] Slack/PagerDuty notifications

---

## 📚 Documentation Map

| Document | Purpose | Audience |
|----------|---------|----------|
| [README.md](../README.md) | Project overview & workflow | Everyone |
| [SETUP_GUIDE.md](./SETUP_GUIDE.md) | Step-by-step setup | DevOps/SRE |
| [JENKINS_GUIDE.md](./JENKINS_GUIDE.md) | Jenkins configuration | DevOps engineers |
| [This File](./PROJECT_STRUCTURE.md) | Folder structure reference | Developers |

---

## ✅ Validation Checklist

After setup, verify:

```bash
# AWS Infrastructure
☐ terraform apply completed successfully
☐ EC2 instance running
☐ EKS cluster created
☐ S3 bucket created

# Jenkins
☐ Jenkins accessible at http://<IP>:8080
☐ All plugins installed
☐ GitHub credentials added
☐ AWS credentials added
☐ Job created and saved

# GitHub
☐ Code pushed to main branch
☐ Webhook configured in GitHub
☐ Personal access token created

# First Pipeline Run
☐ Pipeline triggered (manual or GitHub webhook)
☐ All 7 stages completed successfully
☐ Application pod running in EKS
☐ LoadBalancer URL generated
☐ Application accessible via URL

# CloudWatch
☐ Log group created
☐ Logs appearing in CloudWatch
☐ No errors in logs

# Cleanup (if starting over)
☐ terraform destroy (to remove AWS resources)
☐ Delete Jenkins from EC2 console
```

---

## 🆘 Support Resources

| Issue | Resource |
|-------|----------|
| Terraform errors | See `AWS-Resources/` and [Terraform Docs](https://www.terraform.io/docs) |
| Jenkins problems | See `jenkins-config/JENKINS_GUIDE.md` |
| Setup questions | See `jenkins-config/SETUP_GUIDE.md` |
| Kubernetes errors | See [kubectl troubleshooting](https://kubernetes.io/docs/tasks/debug/) |
| AWS issues | See [AWS Console](https://console.aws.amazon.com) & CloudTrail logs |

---

## 📞 Contact & Attribution

**Project**: Project-03 CI/CD Pipeline  
**Author**: Akshay (MLOps Architect)  
**Created**: February 2026  
**Framework**: Jenkins → Docker → ECR → EKS → CloudWatch → S3

---

## License

MIT License - See LICENSE file for details

---

**Last Updated**: February 22, 2026  
**Current Version**: 1.0
