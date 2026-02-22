pipeline {
    agent any

    environment {
        // AWS region where all resources are deployed
        AWS_REGION = 'ap-south-1'

        // AWS credentials from Jenkins credentials store
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')

        // Your AWS account ID — add this in Jenkins credentials as Secret text
        AWS_ACCOUNT_ID = credentials('AWS_ACCOUNT_ID')

        // ECR registry URL — built from account ID and region
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        // ECR repository name — must match what you created
        ECR_REPO_NAME = 'project03-app'

        // Image tag = Jenkins build number (e.g. 1, 2, 3)
        // Every build gets a unique tag
        IMAGE_TAG = "${BUILD_NUMBER}"

        // EKS cluster name — must match cluster.tf
        EKS_CLUSTER_NAME = 'project03-cluster'

        // Kubernetes namespace where app is deployed
        K8S_NAMESPACE = 'default'
    }

    stages {

        // ─────────────────────────────────────────
        // Stage 1 — Pull latest code from GitHub
        // ─────────────────────────────────────────
        stage('Checkout Code') {
            steps {
                echo '===== Pulling code from GitHub ====='

                // checkout scm = pulls code from the repo
                // configured in Jenkins pipeline settings
                checkout scm

                echo '✓ Code checked out successfully'
            }
        }

        // ─────────────────────────────────────────
        // Stage 2 — Build Docker image
        // ─────────────────────────────────────────
        stage('Build Docker Image') {
            steps {
                echo '===== Building Docker image ====='
                script {
                    sh '''
                        echo "Building image: ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"

                        # build image with build number tag
                        docker build -t ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} .

                        # also tag as latest for easy reference
                        docker tag ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} \
                                   ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest

                        # verify image was built
                        docker images | grep project03
                    '''
                }
                echo '✓ Docker image built successfully'
            }
        }

        // ─────────────────────────────────────────
        // Stage 3 — Push image to Amazon ECR
        // ─────────────────────────────────────────
        stage('Push to ECR') {
            steps {
                echo '===== Pushing image to Amazon ECR ====='
                script {
                    sh '''
                        # login to ECR — token valid for 12 hours
                        echo "Logging into ECR..."
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        # create ECR repo if it doesnt exist already
                        # || true means dont fail if it already exists
                        echo "Creating ECR repository if not exists..."
                        aws ecr describe-repositories \
                            --repository-names ${ECR_REPO_NAME} \
                            --region ${AWS_REGION} > /dev/null 2>&1 || \
                        aws ecr create-repository \
                            --repository-name ${ECR_REPO_NAME} \
                            --region ${AWS_REGION}

                        # push image with build number tag
                        echo "Pushing image tag: ${IMAGE_TAG}"
                        docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}

                        # push image with latest tag
                        echo "Pushing image tag: latest"
                        docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:latest
                    '''
                }
                echo '✓ Image pushed to ECR successfully'
            }
        }

        // ─────────────────────────────────────────
        // Stage 4 — Connect kubectl to EKS cluster
        // ─────────────────────────────────────────
        stage('Update kubeconfig') {
            steps {
                echo '===== Configuring kubectl for EKS cluster ====='
                script {
                    sh '''
                        # update kubeconfig so kubectl points to EKS
                        aws eks update-kubeconfig \
                            --name ${EKS_CLUSTER_NAME} \
                            --region ${AWS_REGION}

                        # verify kubectl can reach the cluster
                        kubectl cluster-info
                        kubectl get nodes
                    '''
                }
                echo '✓ kubeconfig updated successfully'
            }
        }

        // ─────────────────────────────────────────
        // Stage 5 — Deploy app to EKS
        // ─────────────────────────────────────────
        stage('Deploy to EKS') {
            steps {
                echo '===== Deploying to EKS cluster ====='
                script {
                    sh '''
                        # apply all yaml files inside k8s/ folder
                        # deployment.yaml + service.yaml + configmap.yaml
                        echo "Applying Kubernetes manifests..."
                        kubectl apply -f k8s/ -n ${K8S_NAMESPACE}

                        # update deployment with new image tag
                        # this triggers a rolling update in Kubernetes
                        echo "Updating image to: ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
                        kubectl set image deployment/project03-app \
                            project03-app=${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG} \
                            -n ${K8S_NAMESPACE} || true

                        # wait max 5 minutes for rollout to finish
                        # fails pipeline if pods dont come up in time
                        echo "Waiting for rollout..."
                        kubectl rollout status deployment/project03-app \
                            -n ${K8S_NAMESPACE} --timeout=5m
                    '''
                }
                echo '✓ Deployment to EKS successful'
            }
        }

        // ─────────────────────────────────────────
        // Stage 6 — Verify deployment is healthy
        // ─────────────────────────────────────────
        stage('Verify Deployment') {
            steps {
                echo '===== Verifying EKS Deployment ====='
                script {
                    sh '''
                        echo "========== POD STATUS =========="
                        kubectl get pods -n ${K8S_NAMESPACE}

                        echo "========== SERVICES =========="
                        kubectl get svc -n ${K8S_NAMESPACE}

                        echo "========== LOAD BALANCER URL =========="
                        # get external URL of the app
                        kubectl get svc project03-service \
                            -n ${K8S_NAMESPACE} \
                            -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' \
                            || echo "LoadBalancer IP not yet assigned"
                    '''
                }
                echo '✓ Verification complete'
            }
        }

        // ─────────────────────────────────────────
        // Stage 7 — Show recent app logs
        // Note: removed -f flag to prevent pipeline hanging
        // ─────────────────────────────────────────
        stage('View Application Logs') {
            steps {
                echo '===== Recent Application Logs ====='
                script {
                    sh '''
                        # --tail=50 = show last 50 lines only
                        # removed -f flag — -f follows logs forever
                        # and would hang the pipeline ❌
                        kubectl logs deployment/project03-app \
                            -n ${K8S_NAMESPACE} \
                            --tail=50 \
                            --timestamps=true \
                            || echo "No logs available yet"
                    '''
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // Post actions — run after all stages
    // ─────────────────────────────────────────
    post {

        // runs only if all stages passed
        success {
            echo '''
            ✅ PIPELINE EXECUTED SUCCESSFULLY!
            
            Image: ${ECR_REPO_NAME}:${IMAGE_TAG}
            Cluster: ${EKS_CLUSTER_NAME}
            Namespace: ${K8S_NAMESPACE}
            Build: ${BUILD_NUMBER}
            '''
        }

        // runs only if any stage failed
        failure {
            echo '''
            ❌ PIPELINE FAILED!
            
            Check Console Output for errors.
            Common issues:
            1. Docker build failed  → check Dockerfile
            2. ECR push failed      → check AWS credentials
            3. EKS deploy failed    → check kubeconfig + IAM roles
            4. Image pull failed    → check ECR image exists
            '''
        }

        // always runs — success or failure
        always {
            // clean workspace after every build
            // frees up disk space on Jenkins VM
            echo 'Cleaning up workspace...'
            deleteDir()
        }
    }
}
