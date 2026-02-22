#!/bin/bash

###############################################################################
# ECR Push Script - Pushes Docker image to Amazon ECR
# Usage: ./ecr-push.sh [IMAGE_TAG]
# Example: ./ecr-push.sh 1.0
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   ECR Push Script${NC}"
echo -e "${BLUE}========================================${NC}"

# Display configuration
echo -e "${YELLOW}Configuration:${NC}"
echo "  AWS Region: $AWS_REGION"
echo "  AWS Account ID: $AWS_ACCOUNT_ID"
echo "  ECR Registry: $ECR_REGISTRY"
echo "  Repository: $ECR_REPO_NAME"
echo "  Image Tag: $IMAGE_TAG"
echo ""

FULL_IMAGE_NAME="${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
LATEST_IMAGE_NAME="${ECR_REGISTRY}/${ECR_REPO_NAME}:latest"

# Step 1: Login to ECR
echo -e "${YELLOW}Step 1: Logging in to Amazon ECR...${NC}"
if aws ecr get-login-password --region "$AWS_REGION" | \
   docker login --username AWS --password-stdin "$ECR_REGISTRY"; then
    echo -e "${GREEN}✅ Successfully logged in to ECR${NC}"
else
    echo -e "${RED}❌ Failed to log in to ECR${NC}"
    echo "Troubleshooting:"
    echo "  1. Check AWS credentials: aws sts get-caller-identity"
    echo "  2. Verify IAM permissions: ecr:GetAuthorizationToken"
    echo "  3. Check AWS_REGION: $AWS_REGION"
    exit 1
fi

echo ""

# Step 2: Create ECR repository if not exists
echo -e "${YELLOW}Step 2: Checking ECR repository...${NC}"
if aws ecr describe-repositories \
    --repository-names "$ECR_REPO_NAME" \
    --region "$AWS_REGION" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Repository exists: $ECR_REPO_NAME${NC}"
else
    echo -e "${YELLOW}Creating ECR repository: $ECR_REPO_NAME${NC}"
    aws ecr create-repository \
        --repository-name "$ECR_REPO_NAME" \
        --region "$AWS_REGION"
    echo -e "${GREEN}✅ Repository created${NC}"
fi

echo ""

# Step 3: Push images to ECR
echo -e "${YELLOW}Step 3: Pushing images to ECR...${NC}"

echo "Pushing: $FULL_IMAGE_NAME"
if docker push "$FULL_IMAGE_NAME"; then
    echo -e "${GREEN}✅ Successfully pushed $IMAGE_TAG tag${NC}"
else
    echo -e "${RED}❌ Failed to push $IMAGE_TAG tag${NC}"
    exit 1
fi

echo ""

echo "Pushing: $LATEST_IMAGE_NAME"
if docker push "$LATEST_IMAGE_NAME"; then
    echo -e "${GREEN}✅ Successfully pushed latest tag${NC}"
else
    echo -e "${RED}❌ Failed to push latest tag${NC}"
    exit 1
fi

echo ""

# Step 4: Verify images in ECR
echo -e "${YELLOW}Step 4: Verifying images in ECR...${NC}"
echo ""
aws ecr describe-images \
    --repository-name "$ECR_REPO_NAME" \
    --region "$AWS_REGION" \
    --query 'imageDetails[*].[imageTags, imageSizeInBytes, imagePushedAt]' \
    --output table

echo ""
echo -e "${GREEN}✅ Push complete!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Deploy to EKS: ./eks-deploy.sh"
echo "  2. Image URI: $FULL_IMAGE_NAME"
