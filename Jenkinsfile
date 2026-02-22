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
                echo "✓ Code checked out successfully"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '===== Building Docker image ====='
                script {
                    sh '''
                        echo "Building Docker image: ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
                        docker build -t ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} .
                        docker tag ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} \
                                  ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest
                        
                        # List built images
                        docker images | grep project03
                    '''
                }
                echo "✓ Docker image built successfully"
            }
        }

        stage('Push to ECR') {
            steps {
                echo '===== Pushing image to Amazon ECR ====='
                script {
                    sh '''
                        # Login to ECR
                        echo "Logging into ECR: ${ECR_REGISTRY}"
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        
                        # Create ECR repository if not exists
                        echo "Creating ECR repository if not exists..."
                        aws ecr describe-repositories \
                            --repository-names ${ECR_REPO_NAME} \
                            --region ${AWS_REGION} > /dev/null 2>&1 || \
                        aws ecr create-repository \
                            --repository-name ${ECR_REPO_NAME} \
                            --region ${AWS_REGION}
                        
                        # Push images
                        echo "Pushing image with tag: ${IMAGE_TAG}"
                        docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}
                        echo "Pushing image with tag: latest"
                        docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest
                        
                        # List images in ECR
                        aws ecr describe-images --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}
                    '''
                }
                echo "✓ Image pushed to ECR successfully"
            }
        }

        stage('Update kubeconfig') {
            steps {
                echo '===== Configuring kubectl for EKS cluster ====='
                script {
                    sh '''
                        echo "Updating kubeconfig for cluster: ${EKS_CLUSTER_NAME}"
                        aws eks update-kubeconfig \
                            --name ${EKS_CLUSTER_NAME} \
                            --region ${AWS_REGION}
                        
                        # Verify connection
                        kubectl cluster-info
                        kubectl get nodes
                    '''
                }
                echo "✓ kubeconfig updated successfully"
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo '===== Deploying to EKS cluster ====='
                script {
                    sh '''
                        # Create namespace if not exists
                        echo "Creating namespace: ${K8S_NAMESPACE}"
                        kubectl create namespace ${K8S_NAMESPACE} || true
                        
                        # Apply Kubernetes manifests
                        echo "Applying Kubernetes manifests..."
                        kubectl apply -f k8s/ -n ${K8S_NAMESPACE}
                        
                        # Update image in deployment
                        echo "Updating deployment image to: ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
                        kubectl set image deployment/project03-app \
                            project03-app=${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} \
                            -n ${K8S_NAMESPACE} || true
                        
                        # Wait for rollout to complete (timeout: 5 minutes)
                        echo "Waiting for rollout to complete..."
                        kubectl rollout status deployment/project03-app \
                            -n ${K8S_NAMESPACE} --timeout=5m
                    '''
                }
                echo "✓ Deployment to EKS successful"
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '===== Verifying EKS Deployment ====='
                script {
                    sh '''
                        echo "========== POD STATUS =========="
                        kubectl get pods -n ${K8S_NAMESPACE}
                        
                        echo ""
                        echo "========== SERVICES =========="
                        kubectl get svc -n ${K8S_NAMESPACE}
                        
                        echo ""
                        echo "========== DEPLOYMENT STATUS =========="
                        kubectl describe deployment project03-app -n ${K8S_NAMESPACE}
                        
                        echo ""
                        echo "========== SERVICE ENDPOINT =========="
                        kubectl get svc project03-service -n ${K8S_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || echo "LoadBalancer IP not yet assigned"
                    '''
                }
                echo "✓ Verification complete"
            }
        }

        stage('View Application Logs') {
            steps {
                echo '===== Recent Application Logs ====='
                script {
                    sh '''
                        echo "Fetching logs from deployment (last 50 lines)..."
                        kubectl logs -f deployment/project03-app -n ${K8S_NAMESPACE} --tail=50 --timestamps=true || echo "No logs available yet"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '''
            ╔═══════════════════════════════════════════════════════╗
            ║  ✅ PIPELINE EXECUTED SUCCESSFULLY!                   ║
            ╚═══════════════════════════════════════════════════════╝
            
            📊 Deployment Summary:
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            🐳 Docker Image: ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}
            ☸️  Cluster: ${EKS_CLUSTER_NAME} (${AWS_REGION})
            📦 Namespace: ${K8S_NAMESPACE}
            🔗 Build Number: ${BUILD_NUMBER}
            
            📈 Next Steps:
            1. Get Load Balancer URL:
               kubectl get svc project03-service -n ${K8S_NAMESPACE}
            2. View logs:
               kubectl logs -f deployment/project03-app -n ${K8S_NAMESPACE}
            3. Access application:
               http://<LOAD_BALANCER_URL>
            '''
        }
        failure {
            echo '''
            ╔═══════════════════════════════════════════════════════╗
            ║  ❌ PIPELINE FAILED!                                  ║
            ╚═══════════════════════════════════════════════════════╝
            
            🔍 Troubleshooting Steps:
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            1. Check Console Output above for error details
            2. Common issues:
               • Docker build failed: Check Dockerfile syntax
               • ECR push failed: Verify AWS credentials & permissions
               • EKS deploy failed: Check kubeconfig, IAM roles
               • Image pull failed: Check ECR image exists
            3. Manual verification:
               aws ecr describe-images --repository-name project03-flask-app
               kubectl get events -n ${K8S_NAMESPACE}
            '''
        }
        always {
            echo '🧹 Cleaning up workspace...'
            deleteDir()
        }
    }
}
