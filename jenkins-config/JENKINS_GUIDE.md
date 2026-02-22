# Jenkins Configuration Guide

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Jenkins Job Configuration](#jenkins-job-configuration)
3. [GitHub Integration](#github-integration)
4. [Credentials Configuration](#credentials-configuration)
5. [Pipeline Troubleshooting](#pipeline-troubleshooting)

---

## Initial Setup

### Install Required Jenkins Plugins

1. **Navigate to Plugin Manager**
   - Jenkins Dashboard → Manage Jenkins → Manage Plugins

2. **Install these plugins:**
   - ✅ GitHub plugin
   - ✅ GitHub Integration
   - ✅ Pipeline
   - ✅ Docker Pipeline
   - ✅ CloudBees AWS Credentials
   - ✅ AWS Authorization
   - ✅ Timestamper
   - ✅ AnsiColor (for colored output)

3. **Restart Jenkins**
   ```
   sudo systemctl restart jenkins
   ```

---

## Jenkins Job Configuration

### Create Jenkins Pipeline Job

**Step 1: Create New Job**
```
Jenkins Dashboard → New Item
  Name: project03-pipeline
  Type: Pipeline
  Click: OK
```

**Step 2: Configure Pipeline**
```
Build Triggers:
  ☑ GitHub hook trigger for GITScm polling
  
Pipeline:
  Definition: Pipeline script from SCM
  SCM: Git
    Repository URL: https://github.com/YOUR_USERNAME/Project-03.git
    Credentials: github-credentials (create if not exists)
    Branches to build: */main
    Script Path: Jenkinsfile
  
  Advanced:
    Git submodules: ✓
    Shallow clone: (optional)
```

**Step 3: Save Job**

---

## GitHub Integration

### Create GitHub Repository

```bash
# Initialize if not already done
git init
git add .
git commit -m "Initial commit: Project-03 pipeline setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/Project-03.git
git push -u origin main
```

### Configure GitHub Webhook

**GitHub Repository Settings → Webhooks**

1. **Click: Add webhook**
2. **Payload URL**: `http://<JENKINS_IP>:8080/github-webhook/`
3. **Content type**: `application/json`
4. **Events**: 
   - ✓ Push events
   - ☐ Pull requests
5. **Active**: ✓
6. **SSH**: `Save webhook`

### Create GitHub Personal Access Token

**GitHub Settings → Developer settings → Personal access tokens**

1. **Generate new token**
2. **Scopes**:
   - ✓ repo (full control of private repositories)
   - ✓ admin:repo_hook (write access to hooks)
3. **Generate token & save** (you won't see it again)

---

## Credentials Configuration

### GitHub Credentials

**Jenkins → Manage Jenkins → Manage Credentials → System**

1. **Global credentials → Add Credentials**
   - Kind: **Username with password**
   - Username: Your GitHub username
   - Password: Personal Access Token (from above)
   - ID: `github-credentials`
   - Description: `GitHub API Token`
   - Click: Create

### AWS Credentials (for ECR & EKS)

**Jenkins → Manage Jenkins → Manage Credentials → System**

1. **Global credentials → Add Credentials**
   - Kind: **AWS Credentials**
   - Access Key ID: (from IAM user)
   - Secret Access Key: (from IAM user)
   - ID: `aws-credentials`
   - Description: `AWS ECR & EKS Credentials`
   - Click: Create

2. **Add AWS Account ID Credential**
   - Kind: **Secret text**
   - Secret: `123456789012` (your AWS Account ID)
   - ID: `AWS_ACCOUNT_ID`
   - Click: Create

### Jenkins System Configuration

**Jenkins → Manage Jenkins → Configure System**

1. **GitHub Server**
   - GitHub Server: Add
   - Name: `GitHub`
   - API URL: `https://api.github.com`
   - Credentials: `github-credentials`
   - Test connection

2. **AWS Config**
   - Default Credentials Provider: Select `aws-credentials`

---

## Pipeline Troubleshooting

### Check Jenkins Logs

```bash
# SSH into Jenkins server
ssh -i project03-jenkins-key.pem ubuntu@<JENKINS_IP>

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Check Jenkins home directory
ls -la /var/lib/jenkins/workspace/project03-pipeline/
```

### Verify Docker Access in Jenkins

```bash
# SSH into Jenkins server
ssh -i project03-jenkins-key.pem ubuntu@<JENKINS_IP>

# Check if jenkins user can access docker
sudo -u jenkins docker ps

# If error, add jenkins to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Verify AWS Credentials in Jenkins

```bash
# SSH into Jenkins server
ssh -i project03-jenkins-key.pem ubuntu@<JENKINS_IP>

# Check AWS CLI configured
aws sts get-caller-identity

# Test ECR login
aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com
```

### Test GitHub Webhook

**Jenkins → project03-pipeline → Configure → GitHub hook log**

1. Look for webhook delivery logs
2. If no logs, check:
   - GitHub webhook URL is correct
   - Jenkins is accessible from GitHub (public IP/firewall)
   - Webhook secret (if configured) matches

### Common Pipeline Failures

| Error | Cause | Solution |
|-------|-------|----------|
| `Failed to connect to GitHub` | Invalid token or network issue | Verify token, check firewall rules |
| `Docker build failed` | Invalid Dockerfile syntax | Check Dockerfile for errors |
| `ECR login failed` | Invalid AWS credentials | Verify IAM user credentials, re-add in Jenkins |
| `kubeconfig not found` | EKS cluster unreachable | Verify cluster exists, check IAM permissions |
| `Image pull error in EKS` | Image doesn't exist in ECR | Check image was pushed, verify URI in deployment |

### Debug Pipeline Manually

```bash
# SSH into Jenkins VM
ssh -i project03-jenkins-key.pem ubuntu@<JENKINS_IP>

# Navigate to workspace
cd /var/lib/jenkins/workspace/project03-pipeline/

# Test Docker build
docker build -t test:latest .

# Test AWS ECR login
aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com

# Test kubectl access
aws eks update-kubeconfig --name project03-cluster --region ap-south-1
kubectl get nodes
```

---

## Pipeline Execution Timeline

**Expected execution time: 5-10 minutes**

| Stage | Typical Duration |
|-------|------------------|
| Checkout Code | 30 seconds |
| Build Docker Image | 2-3 minutes |
| Push to ECR | 1-2 minutes |
| Update kubeconfig | 10 seconds |
| Deploy to EKS | 1-2 minutes |
| Verify Deployment | 1 minute |
| View Logs | 30 seconds |

---

## Monitoring Pipeline Execution

### Jenkins UI

```
Jenkins Dashboard → project03-pipeline → Build History
  → Click on build number → Console Output
```

### Real-time Logs

```bash
# SSH into Jenkins
ssh -i project03-jenkins-key.pem ubuntu@<JENKINS_IP>

# Tail Jenkins log
sudo tail -f /var/log/jenkins/jenkins.log | grep project03

# Monitor docker daemon
sudo journalctl -u docker -f
```

### GitHub Webhook Deliveries

**GitHub Repository → Settings → Webhooks → Recent deliveries**

- View payload sent to Jenkins
- Check response status (200 = success)
- Verify timestamp matches pipeline trigger time

---

## Advanced Configuration

### Slack Notifications

**Add to Jenkinsfile (in `post` section):**

```groovy
post {
    success {
        slackSend(
            channel: '#deployments',
            message: "✅ project03 deployed successfully",
            color: 'good'
        )
    }
    failure {
        slackSend(
            channel: '#deployments',
            message: "❌ project03 deployment failed",
            color: 'danger'
        )
    }
}
```

### Email Notifications

**Jenkins → Configure System → E-mail Notification**

1. SMTP Server: (your mail server)
2. Default user e-mail suffix: @example.com
3. Reply-To Address: jenkins@example.com

**Add to Jenkinsfile:**

```groovy
post {
    always {
        emailext(
            subject: "Build ${BUILD_NUMBER}: ${BUILD_STATUS}",
            body: "Check console output at ${BUILD_URL}",
            to: "your-email@example.com"
        )
    }
}
```

### Scheduled Builds

**Project → Configure → Build Triggers**

```
Poll SCM: H H * * *
  (Polls GitHub daily for changes)
```

---

## Security Best Practices

1. **Credentials**
   - Never commit AWS keys or PATs
   - Use Jenkins Credentials Store
   - Rotate IAM keys quarterly

2. **Access Control**
   - Enable authentication
   - Use role-based access control (RBAC)
   - Limit job visibility

3. **Network Security**
   - Use VPN for Jenkins access (if on cloud)
   - Configure firewall rules
   - Use HTTPS for Jenkins URL

4. **Audit Logging**
   - Enable Jenkins Job Logging
   - Monitor failed pipeline runs
   - Archive build logs

---

## Project Organization

```
Jenkins Home: /var/lib/jenkins/

Workspace: /var/lib/jenkins/workspace/project03-pipeline/
  ├── main.py
  ├── dockerfile
  ├── Jenkinsfile
  ├── README.md
  ├── templates/
  ├── AWS-Resources/
  └── k8s/

Logs: /var/lib/jenkins/logs/
Pipeline Artifacts: /var/lib/jenkins/workspace/project03-pipeline/
```

---

## Post-Deployment Verification

After first successful deployment:

```bash
# 1. Check EKS resources
kubectl get deployments
kubectl get services
kubectl get pods

# 2. Get LoadBalancer URL
kubectl get svc project03-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# 3. Test application
curl http://<LOAD_BALANCER_URL>

# 4. Check CloudWatch logs
aws logs tail /aws/eks/project03-cluster --follow

# 5. Verify images in ECR
aws ecr describe-images --repository-name project03-flask-app
```

---

## Support

- **Jenkins Logs**: `/var/log/jenkins/jenkins.log`
- **Docker Logs**: `sudo journalctl -u docker -f`
- **System Logs**: `sudo tail -f /var/log/syslog`
- **Jenkins Documentation**: https://www.jenkins.io/doc/

---

**Last Updated**: February 2026
