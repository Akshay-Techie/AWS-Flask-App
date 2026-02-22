variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"
}

# AMI ID for Ubuntu 22.04 LTS
# This is region specific — change if using a different region
# Find AMIs at: https://cloud-images.ubuntu.com/locator/ec2/
variable "ami_id" {
  description = "Ubuntu AMI ID (region specific)"
  type        = string

  # Default is Ubuntu 22.04 for us-east-1 region
  default = "ami-0e35ddab05955cf57"
}

# EC2 instance type for Jenkins server
# t3.medium = 2 vCPU, 4GB RAM — good balance for Jenkins
variable "instance_type" {
  description = "EC2 instance type"
  type        = string

  # t3.medium recommended — t3.micro is too small for Jenkins
  default = "t3.micro"
}

# Name of your existing EC2 Key Pair in AWS
# Used to SSH into the Jenkins server
# Create one at: EC2 Console → Key Pairs → Create Key Pair
variable "keypair_name" {
  description = "AWS key pair name"
  type        = string
}
