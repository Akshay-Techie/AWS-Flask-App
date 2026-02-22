#!/bin/bash

###############################################################################
# EKS Deploy Script - Deploys Docker image to Amazon EKS
# Usage: ./eks-deploy.sh [IMAGE_TAG] [NAMESPACE]
# Example: ./eks-deploy.sh 1.0 default
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-ap-south-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPO_NAME="${ECR_REPO_NAME:-project03-flask-app}"
IMAGE_TAG="${1:-latest}"
K8S_NAMESPACE="${2:-default}"
EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-project03-cluster}"
K8S_MANIFESTS_DIR="${K8S_MANIFESTS_DIR:-./k8s}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   EKS Deploy Script${NC}"
echo -e "${BLUE}========================================${NC}"

# Display configuration
echo -e "${YELLOW}Configuration:${NC}"
echo "  AWS Region: $AWS_REGION"
echo "  EKS Cluster: $EKS_CLUSTER_NAME"
echo "  ECR Registry: $ECR_REGISTRY"
echo "  Repository: $ECR_REPO_NAME"
echo "  Image Tag: $IMAGE_TAG"
echo "  Kubernetes Namespace: $K8S_NAMESPACE"
echo "  Manifests Directory: $K8S_MANIFESTS_DIR"
echo ""

FULL_IMAGE_NAME="${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"

# Step 1: Update kubeconfig
echo -e "${YELLOW}Step 1: Updating kubeconfig for EKS cluster...${NC}"
if aws eks update-kubeconfig \
    --name "$EKS_CLUSTER_NAME" \
    --region "$AWS_REGION"; then
    echo -e "${GREEN}✅ kubeconfig updated successfully${NC}"
else
    echo -e "${RED}❌ Failed to update kubeconfig${NC}"
    echo "Troubleshooting:"
    echo "  1. Verify EKS cluster exists: aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION"
    echo "  2. Check AWS credentials and IAM permissions"
    exit 1
fi

echo ""

# Step 2: Verify cluster connectivity
echo -e "${YELLOW}Step 2: Verifying cluster connectivity...${NC}"
if kubectl cluster-info > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Successfully connected to cluster${NC}"
    kubectl cluster-info
else
    echo -e "${RED}❌ Failed to connect to cluster${NC}"
    exit 1
fi

echo ""

# Step 3: Create namespace
echo -e "${YELLOW}Step 3: Creating namespace: $K8S_NAMESPACE${NC}"
kubectl create namespace "$K8S_NAMESPACE" || echo "Namespace already exists"

echo ""

# Step 4: Check if manifests directory exists
if [ ! -d "$K8S_MANIFESTS_DIR" ]; then
    echo -e "${RED}❌ Error: Manifests directory not found at $K8S_MANIFESTS_DIR${NC}"
    exit 1
fi

# Step 5: Apply Kubernetes manifests
echo -e "${YELLOW}Step 4: Applying Kubernetes manifests from $K8S_MANIFESTS_DIR...${NC}"
if kubectl apply -f "$K8S_MANIFESTS_DIR" -n "$K8S_NAMESPACE"; then
    echo -e "${GREEN}✅ Manifests applied successfully${NC}"
else
    echo -e "${RED}❌ Failed to apply manifests${NC}"
    exit 1
fi

echo ""

# Step 6: Update deployment image
echo -e "${YELLOW}Step 5: Updating deployment image to $FULL_IMAGE_NAME...${NC}"
if kubectl set image deployment/project03-app \
    "project03-app=$FULL_IMAGE_NAME" \
    -n "$K8S_NAMESPACE"; then
    echo -e "${GREEN}✅ Deployment image updated${NC}"
else
    echo -e "${YELLOW}⚠️  Note: Deployment might not exist yet (first deployment)${NC}"
fi

echo ""

# Step 7: Wait for rollout
echo -e "${YELLOW}Step 6: Waiting for deployment rollout (timeout: 5 minutes)...${NC}"
if kubectl rollout status deployment/project03-app \
    -n "$K8S_NAMESPACE" \
    --timeout=5m; then
    echo -e "${GREEN}✅ Deployment rolled out successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Rollout status check timed out or failed${NC}"
    echo "Pod status:"
    kubectl get pods -n "$K8S_NAMESPACE"
fi

echo ""

# Step 8: Verify deployment
echo -e "${YELLOW}Step 7: Verifying deployment status...${NC}"
echo ""
echo -e "${BLUE}Pods:${NC}"
kubectl get pods -n "$K8S_NAMESPACE" -o wide

echo ""
echo -e "${BLUE}Services:${NC}"
kubectl get svc -n "$K8S_NAMESPACE" -o wide

echo ""
echo -e "${BLUE}Deployment Details:${NC}"
kubectl describe deployment project03-app -n "$K8S_NAMESPACE" || echo "Deployment not found"

echo ""

# Step 9: Get Load Balancer URL
echo -e "${YELLOW}Step 8: Getting LoadBalancer endpoint...${NC}"
LB_ENDPOINT=$(kubectl get svc project03-service -n "$K8S_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not yet assigned")

if [ "$LB_ENDPOINT" != "Not yet assigned" ] && [ ! -z "$LB_ENDPOINT" ]; then
    echo -e "${GREEN}✅ Application accessible at:${NC}"
    echo -e "${BLUE}   http://$LB_ENDPOINT${NC}"
else
    echo -e "${YELLOW}⚠️  LoadBalancer IP not yet assigned (may take 1-2 minutes)${NC}"
    echo "Check again with:"
    echo "  kubectl get svc project03-service -n $K8S_NAMESPACE"
fi

echo ""

# Step 10: Display logs
echo -e "${YELLOW}Step 9: Recent application logs (last 20 lines):${NC}"
echo ""
kubectl logs -f deployment/project03-app -n "$K8S_NAMESPACE" --tail=20 --timestamps=true 2>/dev/null || \
    echo "No logs available yet (pods may still be starting)"

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  View logs: kubectl logs -f deployment/project03-app -n $K8S_NAMESPACE"
echo "  Pod status: kubectl get pods -n $K8S_NAMESPACE -w"
echo "  Describe pod: kubectl describe pod <POD_NAME> -n $K8S_NAMESPACE"
echo "  Port forward: kubectl port-forward svc/project03-service 8080:80 -n $K8S_NAMESPACE"
echo "  Scale deployment: kubectl scale deployment project03-app --replicas=5 -n $K8S_NAMESPACE"
echo "  Troubleshoot: kubectl get events -n $K8S_NAMESPACE"
