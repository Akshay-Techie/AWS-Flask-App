#!/bin/bash

###############################################################################
# Docker Build Script - Builds and tags Docker image
# Usage: ./docker-build.sh [IMAGE_TAG]
# Example: ./docker-build.sh 1.0
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
DOCKERFILE="${DOCKERFILE:-dockerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-$(pwd)}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Docker Build Script${NC}"
echo -e "${BLUE}========================================${NC}"

# Display configuration
echo -e "${YELLOW}Configuration:${NC}"
echo "  AWS Region: $AWS_REGION"
echo "  AWS Account ID: $AWS_ACCOUNT_ID"
echo "  ECR Registry: $ECR_REGISTRY"
echo "  Repository: $ECR_REPO_NAME"
echo "  Image Tag: $IMAGE_TAG"
echo "  Dockerfile: $DOCKERFILE"
echo "  Build Context: $BUILD_CONTEXT"
echo ""

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
    echo -e "${RED}❌ Error: Dockerfile not found at $DOCKERFILE${NC}"
    exit 1
fi

# Build Docker image
echo -e "${YELLOW}Step 1: Building Docker image...${NC}"
FULL_IMAGE_NAME="${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
LATEST_IMAGE_NAME="${ECR_REGISTRY}/${ECR_REPO_NAME}:latest"

docker build \
    -f "$DOCKERFILE" \
    -t "$FULL_IMAGE_NAME" \
    -t "$LATEST_IMAGE_NAME" \
    "$BUILD_CONTEXT"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
else
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

echo ""

# List built images
echo -e "${YELLOW}Step 2: Verifying built images...${NC}"
docker images | grep project03 || echo "No project03 images found"

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Push to ECR: ./ecr-push.sh"
echo "  2. Or manually:"
echo "     docker push $FULL_IMAGE_NAME"
echo "     docker push $LATEST_IMAGE_NAME"
