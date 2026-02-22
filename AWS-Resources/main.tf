terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.33.0"
    }
    
    # Random provider — used to generate unique random values
    # Used in aws-s3.tf to create unique S3 bucket name
    random = {
      source  = "hashicorp/random"  # official HashiCorp random provider
      version = "3.7.2"             # locked to this exact version
    }
    # TLS provider — needed to fetch the OIDC certificate
    # from EKS cluster for the OIDC identity provider setup
    # Without this, data "tls_certificate" in cluster.tf will fail
    tls = {
      source  = "hashicorp/tls"  # official HashiCorp TLS provider
      version = "~> 4.0"         # use any 4.x version
    }
  }
}