# Complete Setup Guide — Project-03 CI/CD Pipeline

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] GitHub account with repository created
- [ ] AWS account with billing enabled
- [ ] AWS CLI v2 installed and configured
- [ ] Terraform v1.5+ installed
- [ ] Git installed
- [ ] SSH key pair generated (for EC2 access)
- [ ] Basic understanding of Docker, Kubernetes, and AWS

---

## Phase 1: Local Setup (30 minutes)

### 1.1 Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/Project-03.git
cd Project-03
```

### 1.2 Install Required Tools

**macOS:**
```bash
brew install awscli terraform
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y awscli python3-pip
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 1.3 Configure AWS Credentials

```bash
aws configure
# Enter:
# AWS Access Key ID: [your key]
# AWS Secret Access Key: [your secret]
# Default region: ap-south-1
# Default output format: json
```

### 1.4 Verify Configuration

```bash
aws sts get-caller-identity
# Should show your AWS account info
```

---

## Phase 2: AWS Infrastructure Setup (45 minutes - 1 hour)

### 2.1 Create EC2 Key Pair

```bash
# Create key pair
aws ec2 create-key-pair \
    --key-name project03-jenkins-key \
    --region ap-south-1 \
    --query 'KeyMaterial' --output text > project03-jenkins-key.pem

# Set permissions
chmod 400 project03-jenkins-key.pem

# Verify
ls -la project03-jenkins-key.pem
```

### 2.2 Configure Terraform Variables

Edit `AWS-Resources/terraform.tfvars`:

```hcl
region        = "ap-south-1"
ami_id        = "ami-0e35ddab05955cf57"  # Ubuntu 22.04 LTS
instance_type = "t3.micro"               # Or t3.small for better performance
keypair_name  = "project03-jenkins-key"
```

**Note**: If using different region, update AMI ID from [Ubuntu AMI Locator](https://cloud-images.ubuntu.com/locator/ec2/)

### 2.3 Deploy Infrastructure with Terraform

```bash
cd AWS-Resources

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes (review before applying)
terraform plan

# Apply changes to AWS
terraform apply

# When prompted, review and type: yes
```

**Expected Terraform Outputs:**
```
jenkins_instance_ip = "54.xxx.xxx.xxx"
eks_cluster_name = "project03-cluster"
s3_bucket_name = "logs-s3-bucket-abc123xyz"
```

**Save these outputs** — you'll need them in next steps.

### 2.4 Verify AWS Resources

```bash
# Check EC2 instance
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=Jenkins" \
    --region ap-south-1

# Check EKS cluster
aws eks describe-cluster \
    --name project03-cluster \
    --region ap-south-1

# Check S3 bucket
aws s3 ls | grep logs-s3-bucket
```

---

## Phase 3: Jenkins Server Setup (1.5 hours)

### 3.1 SSH into Jenkins Instance

```bash
# Get Jenkins IP from terraform output
JENKINS_IP="<from terraform output>"

# SSH into server
ssh -i project03-jenkins-key.pem ubuntu@$JENKINS_IP

# You're now inside the Jenkins VM
```

### 3.2 System Updates

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

### 3.3 Install Java

```bash
sudo apt-get install -y openjdk-11-jdk

# Verify
java -version
```

### 3.4 Install Jenkins

```bash
# Add Jenkins repository
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Install Jenkins
sudo apt-get update
sudo apt-get install -y jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Verify
sudo systemctl status jenkins
```

### 3.5 Install Docker

```bash
# Install Docker
sudo apt-get install -y docker.io

# Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

# Verify
docker --version

# Restart Docker to apply group changes
sudo systemctl restart docker
```

### 3.6 Install kubectl

```bash
# Download latest kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
```

### 3.7 Install AWS CLI

```bash
sudo apt-get install -y awscli

# Verify
aws --version
```

### 3.8 Configure AWS Credentials on Jenkins

```bash
# Configure AWS CLI on Jenkins VM
aws configure
# Enter AWS Access Key and Secret from IAM user
# Default region: ap-south-1
```

### 3.9 Initial Jenkins Configuration

```bash
# Get Jenkins initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
# Copy the password
```

**In Web Browser:**

1. Open: `http://<JENKINS_IP>:8080`
2. Paste password from above
3. Click **"Install suggested plugins"** (wait 5 minutes)
4. Create first admin user:
   - Username: `admin`
   - Password: (secure password)
   - Full name: Jenkins Admin
5. Configure Jenkins URL: `http://<JENKINS_IP>:8080/`
6. Click **"Save and Continue"**
7. Click **"Start using Jenkins"**

### 3.10 Install Jenkins Plugins

**Jenkins Dashboard → Manage Jenkins → Manage Plugins → Available**

Search for and install:
- ✅ GitHub plugin
- ✅ GitHub Integration
- ✅ Pipeline
- ✅ Docker Pipeline
- ✅ CloudBees AWS Credentials
- ✅ Timestamper
- ✅ AnsiColor

Then restart Jenkins:
```
Jenkins Dashboard → Manage Jenkins → Restart Jenkins
```

---

## Phase 4: GitHub Configuration (20 minutes)

### 4.1 Push Code to GitHub

```bash
# Back on your local machine
git add .
git commit -m "Initial commit: CI/CD pipeline setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/Project-03.git
git push -u origin main
```

### 4.2 Create GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Click **"Generate new token"**
3. Name: `jenkins-token`
4. Select scopes:
   - ✓ repo (full control)
   - ✓ admin:repo_hook (access to hooks)
5. Click **"Generate token"**
6. **Copy the token** (won't show again)

### 4.3 Create Jenkins GitHub Webhook

**GitHub Repository → Settings → Webhooks**

1. Click **"Add webhook"**
2. Payload URL: `http://<JENKINS_IP>:8080/github-webhook/`
3. Content type: `application/json`
4. Events: ✓ Push events
5. Active: ✓
6. Click **"Add webhook"**

Test connection by pushing a commit to GitHub.

---

## Phase 5: Jenkins Credentials & Job Setup (30 minutes)

### 5.1 Add GitHub Credentials to Jenkins

**Jenkins Dashboard → Manage Jenkins → Manage Credentials → System**

1. Click **"Global credentials (unrestricted)"**
2. Click **"Add Credentials"**
3. Kind: `Username with password`
4. Username: Your GitHub username
5. Password: GitHub Personal Access Token (from Phase 4.2)
6. ID: `github-credentials`
7. Click **"Create"**

### 5.2 Add AWS Credentials to Jenkins

**Jenkins Dashboard → Manage Jenkins → Manage Credentials → System**

1. Click **"Add Credentials"**
2. Kind: `AWS Credentials`
3. Access Key ID: (from IAM user)
4. Secret Access Key: (from IAM user)
5. ID: `aws-credentials`
6. Click **"Create"**

### 5.3 Add AWS Account ID Credential

**Jenkins Dashboard → Manage Jenkins → Manage Credentials**

1. Click **"Add Credentials"**
2. Kind: `Secret text`
3. Secret: `<Your AWS Account ID>` (12 digits)
4. ID: `AWS_ACCOUNT_ID`
5. Click **"Create"**

Get your AWS Account ID:
```bash
aws sts get-caller-identity --query Account --output text
```

### 5.4 Create Jenkins Pipeline Job

**Jenkins Dashboard → New Item**

1. Name: `project03-pipeline`
2. Type: **Pipeline**
3. Click **OK**

**Configure:**

- **Build Triggers**:
  - ✓ GitHub hook trigger for GITScm polling

- **Pipeline**:
  - Definition: `Pipeline script from SCM`
  - SCM: `Git`
    - Repository URL: `https://github.com/YOUR_USERNAME/Project-03.git`
    - Credentials: `github-credentials`
    - Branches to build: `*/main`
    - Script Path: `Jenkinsfile`

- Click **Save**

---

## Phase 6: Test the Pipeline (20 minutes)

### 6.1 Manual Trigger

**Jenkins Dashboard → project03-pipeline → Build Now**

Monitor progress in **Console Output**.

### 6.2 Expected Pipeline Execution

```
Checkout Code
    ↓
Build Docker Image (2-3 min)
    ↓
Push to ECR (1-2 min)
    ↓
Update kubeconfig
    ↓
Deploy to EKS (2-3 min)
    ↓
Verify Deployment (1 min)
    ↓
View Logs
    ↓
✅ SUCCESS
```

**Total time: 6-10 minutes**

### 6.3 Verify Deployment

```bash
# From your local machine
aws eks update-kubeconfig --name project03-cluster --region ap-south-1

# Check pods
kubectl get pods

# Get LoadBalancer URL
kubectl get svc project03-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Test application
curl http://<LOAD_BALANCER_URL>
```

### 6.4 View Application Logs

```bash
# View deployment logs
kubectl logs -f deployment/project03-app

# View CloudWatch logs
aws logs tail /aws/eks/project03-cluster --follow
```

---

## Phase 7: Test GitHub Integration (10 minutes)

### 7.1 Push Code Change

```bash
# Make a small change
echo "# Updated" >> README.md

# Commit and push
git add README.md
git commit -m "Test: trigger pipeline via GitHub webhook"
git push origin main
```

### 7.2 Verify Automatic Trigger

- Jenkins should automatically start a new build
- Monitor at: `http://<JENKINS_IP>:8080/job/project03-pipeline/`

---

## Phase 8: CloudWatch Monitoring Setup (30 minutes)

### 8.1 Create CloudWatch Log Group

```bash
aws logs create-log-group \
    --log-group-name /aws/eks/project03-cluster \
    --region ap-south-1
```

### 8.2 Configure EKS Node Logging

```bash
# SSH into an EKS node (if needed for manual setup)
# For automated setup, use the cloudwatch-config.sh script

bash jenkins-config/scripts/cloudwatch-config.sh install
```

### 8.3 Create CloudWatch Dashboard

```bash
aws cloudwatch put-dashboard \
    --dashboard-name project03-dashboard \
    --region ap-south-1 \
    --dashboard-body '{
      "widgets": [
        {
          "type": "metric",
          "properties": {
            "metrics": [
              ["AWS/ECS", "CPUUtilization"],
              [".", "MemoryUtilization"]
            ],
            "period": 300,
            "stat": "Average",
            "region": "ap-south-1",
            "title": "EKS Metrics"
          }
        }
      ]
    }'
```

### 8.4 View Logs in CloudWatch

```bash
# Real-time logs
aws logs tail /aws/eks/project03-cluster --follow

# Search for errors
aws logs filter-log-events \
    --log-group-name /aws/eks/project03-cluster \
    --filter-pattern "ERROR"
```

---

## Phase 9: S3 Log Archival (20 minutes)

### 9.1 Export CloudWatch Logs to S3

```bash
# Get S3 bucket name from terraform output
S3_BUCKET="<logs-s3-bucket-xxx>"

# Export logs
aws logs create-export-task \
    --log-group-name /aws/eks/project03-cluster \
    --from $(date -d '24 hours ago' +%s)000 \
    --to $(date +%s)000 \
    --destination $S3_BUCKET \
    --destination-prefix "cloudwatch-logs/" \
    --region ap-south-1
```

### 9.2 Verify S3 Objects

```bash
aws s3 ls s3://$S3_BUCKET/cloudwatch-logs/ --recursive
```

### 9.3 Set S3 Lifecycle Policy (optional)

```bash
cat > lifecycle.json << 'EOF'
{
  "Rules": [
    {
      "Id": "archive-old-logs",
      "Status": "Enabled",
      "Prefix": "cloudwatch-logs/",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 90
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
    --bucket $S3_BUCKET \
    --lifecycle-configuration file://lifecycle.json
```

---

## Phase 10: Security Hardening (30 minutes)

### 10.1 Update Jenkins Security

**Jenkins Dashboard → Manage Jenkins → Configure Global Security**

- ✓ Enable CSRF Protection
- ✓ Enable API Token Authentication
- Authorization: `Role-based strategy`

### 10.2 Create Jenkins API Token

**Jenkins Dashboard → Your Profile → API Token**

1. Click **Generate**
2. Save the token
3. Use for programmatic access

### 10.3 Lock Down AWS Permissions

```bash
# Create IAM policy for Jenkins
cat > jenkins-ecr-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:CreateRepository",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:UpdateClusterConfig"
      ],
      "Resource": "arn:aws:eks:ap-south-1:*:cluster/project03-cluster"
    }
  ]
}
EOF

# Create IAM user for Jenkins
aws iam create-user --user-name jenkins-ecr-user
aws iam put-user-policy --user-name jenkins-ecr-user \
    --policy-name jenkins-ecr-policy \
    --policy-document file://jenkins-ecr-policy.json
```

### 10.4 Enable S3 Encryption

```bash
# Enable default encryption for S3 bucket
aws s3api put-bucket-encryption \
    --bucket $S3_BUCKET \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'
```

---

## Deployment Checklist

Before going to production, verify:

- [ ] Pipeline triggers successfully on GitHub push
- [ ] Docker images build without errors
- [ ] Images push to ECR successfully
- [ ] Application deploys to EKS without errors
- [ ] Application is accessible via LoadBalancer URL
- [ ] CloudWatch logs are being collected
- [ ] Logs successfully export to S3
- [ ] Dashboard displays metrics correctly
- [ ] All IAM permissions are minimal (least privilege)
- [ ] Backup of terraform.tfstate exists

---

## Useful Commands Reference

### Jenkins Management
```bash
# Check Jenkins status
sudo systemctl status jenkins

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Restart Jenkins
sudo systemctl restart jenkins
```

### Kubernetes Management
```bash
# Update kubeconfig
aws eks update-kubeconfig --name project03-cluster --region ap-south-1

# Check cluster status
kubectl cluster-info
kubectl get nodes

# View deployments
kubectl get deployments
kubectl get pods
kubectl get svc

# Scale deployment
kubectl scale deployment project03-app --replicas=5

# View logs
kubectl logs -f deployment/project03-app
```

### Docker & ECR
```bash
# Build locally
docker build -t project03:latest .

# Login to ECR
aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com

# Push to ECR
docker push <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/project03-flask-app:latest

# List ECR images
aws ecr describe-images --repository-name project03-flask-app
```

### Monitoring
```bash
# View CloudWatch logs
aws logs tail /aws/eks/project03-cluster --follow

# Search CloudWatch logs
aws logs filter-log-events \
    --log-group-name /aws/eks/project03-cluster \
    --filter-pattern "ERROR"

# Export logs to S3
aws logs create-export-task \
    --log-group-name /aws/eks/project03-cluster \
    --from $(date -d '24 hours ago' +%s)000 \
    --to $(date +%s)000 \
    --destination logs-s3-bucket-xxx \
    --destination-prefix "exports/"
```

---

## Troubleshooting

### Jenkins Won't Start
```bash
sudo systemctl status jenkins
sudo tail -f /var/log/jenkins/jenkins.log
# Check disk space: df -h
# Check memory: free -h
```

### Docker Build Fails
```bash
# Check Dockerfile syntax
docker build -t test:latest .

# Check Docker daemon
sudo systemctl status docker
sudo journalctl -u docker -f
```

### EKS Deployment Error
```bash
# Check kubeconfig
aws eks update-kubeconfig --name project03-cluster --region ap-south-1

# Describe failing pod
kubectl describe pod <POD_NAME>

# Check events
kubectl get events

# Check IAM permissions
aws iam get-user
```

### ECR Push Fails
```bash
# Test ECR login
aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com

# Check if repository exists
aws ecr describe-repositories --repository-names project03-flask-app
```

---

## Learning Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Congratulations! Your CI/CD pipeline is now fully operational! 🚀**
