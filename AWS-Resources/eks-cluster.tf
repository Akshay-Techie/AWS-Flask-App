# ==============================
# EKS Cluster — project03-cluster
# Equivalent to:
# eksctl create cluster --name project03-cluster
# --region ap-south-1 --node-type t3.micro
# --nodes 1 --managed --with-oidc
# ==============================

# -----------------------------------------------
# IAM Role for EKS Control Plane
# EKS needs this role to manage AWS resources
# on behalf of your cluster
# -----------------------------------------------
resource "aws_iam_role" "eks_cluster_role" {

  # Name shown in AWS Console → IAM → Roles
  name = "project03-eks-cluster-role"

  # Trust policy — allows EKS service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          # eks.amazonaws.com = EKS control plane service
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AmazonEKSClusterPolicy to the EKS control plane role
# This gives EKS permission to manage networking, nodes, etc.
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# -----------------------------------------------
# IAM Role for EKS Worker Nodes (Node Group)
# Each EC2 node needs this role to join the cluster
# and pull images from ECR
# -----------------------------------------------
resource "aws_iam_role" "eks_node_role" {

  # Name shown in AWS Console → IAM → Roles
  name = "project03-eks-node-role"

  # Trust policy — allows EC2 instances (nodes) to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          # ec2.amazonaws.com = worker node EC2 instances
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Policy 1 — Allows nodes to connect to EKS cluster
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Policy 2 — Allows nodes to pull Docker images from ECR
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Policy 3 — Allows nodes to pull images from ECR (Elastic Container Registry)
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Policy 4 — Allows nodes to send logs/metrics to CloudWatch
resource "aws_iam_role_policy_attachment" "cloudwatch_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# -----------------------------------------------
# Fetch default VPC — eksctl uses default VPC
# We reuse it here to keep things simple
# -----------------------------------------------
data "aws_vpc" "default" {
  # true = fetch the default VPC of the region (ap-south-1)
  default = true
}

# Fetch all subnets inside the default VPC
# EKS needs at least 2 subnets in different AZs
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    # Reference the default VPC ID fetched above
    values = [data.aws_vpc.default.id]
  }
}

# -----------------------------------------------
# EKS Cluster — Control Plane
# This is the brain of your Kubernetes cluster
# -----------------------------------------------
resource "aws_eks_cluster" "project03" {

  # Cluster name — matches your eksctl command
  name = "project03-cluster"

  # Attach the IAM role so EKS can manage resources
  role_arn = aws_iam_role.eks_cluster_role.arn

  # Kubernetes version — 1.35 is stable as of March 27, 2027
  version = "1.35"

  vpc_config {
    # Pass subnet IDs where nodes will be launched
    # EKS spreads nodes across these subnets (multi-AZ)
    subnet_ids = data.aws_subnets.default.ids

    # true = cluster API endpoint accessible from internet
    # Required for Jenkins (on-prem VM) to run kubectl commands
    endpoint_public_access = true

    # false = no private endpoint (keep simple for now)
    endpoint_private_access = false
  }

  # Enable CloudWatch logging for the control plane
  # Captures API, audit, scheduler logs → CloudWatch
  enabled_cluster_log_types = ["api", "audit", "scheduler", "controllerManager", "authenticator"]

  # EKS cluster depends on this policy being attached first
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name    = "project03-cluster"
    Project = "Project-03"
  }
}

# -----------------------------------------------
# OIDC Provider — equivalent to --with-oidc flag
# Required for IAM Roles for Service Accounts (IRSA)
# Allows pods to assume IAM roles directly
# -----------------------------------------------

# Fetch the TLS certificate of the EKS OIDC endpoint
data "tls_certificate" "eks_oidc" {
  # URL comes from the EKS cluster's OIDC issuer
  url = aws_eks_cluster.project03.identity[0].oidc[0].issuer
}

# Create the OIDC Identity Provider in IAM
resource "aws_iam_openid_connect_provider" "eks_oidc" {

  # OIDC issuer URL from the EKS cluster
  client_id_list = ["sts.amazonaws.com"]

  # Thumbprint of the OIDC certificate for verification
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]

  # OIDC issuer URL — fetched from cluster after creation
  url = aws_eks_cluster.project03.identity[0].oidc[0].issuer
}

# -----------------------------------------------
# Managed Node Group — Worker Nodes
# Equivalent to --node-type t3.micro --nodes 2 --managed
# AWS manages patching and lifecycle of these nodes
# -----------------------------------------------
resource "aws_eks_node_group" "project03_nodes" {

  # Link this node group to the cluster created above
  cluster_name = aws_eks_cluster.project03.name

  # Name of this node group
  node_group_name = "ng-project03"

  # IAM role for worker nodes
  node_role_arn = aws_iam_role.eks_node_role.arn

  # Subnets where worker nodes will be launched
  subnet_ids = data.aws_subnets.default.ids

  # Instance type — t3.micro matches your eksctl command
  instance_types = ["t3.micro"]

  # AMI type — AL2 is standard for EKS managed nodes
  ami_type = "AL2023_x86_64_STANDARD"

  # Disk size for each worker node in GB
  disk_size = 20

  # Scaling configuration
  scaling_config {
    # Minimum nodes in the group
    min_size = 1

    # Maximum nodes the group can scale to
    max_size = 2

    # Desired nodes — matches --nodes 1 in eksctl
    desired_size = 1
  }

  # Update config — how many nodes can be unavailable during update
  update_config {
    max_unavailable = 1
  }

  # Node group depends on all 3 node policies being attached
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]

  tags = {
    Name    = "project03-nodes"
    Project = "Project-03"
  }
}

# ==============================
# Outputs
# ==============================

# Output the cluster name for reference
output "eks_cluster_name" {
  value       = aws_eks_cluster.project03.name
  description = "EKS Cluster Name"
}

# Output the cluster endpoint — used in kubectl config
output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.project03.endpoint
  description = "EKS Cluster API Endpoint"
}

# Output the OIDC issuer URL — needed for IRSA setup
output "eks_oidc_issuer" {
  value       = aws_eks_cluster.project03.identity[0].oidc[0].issuer
  description = "OIDC Issuer URL for IRSA"
}