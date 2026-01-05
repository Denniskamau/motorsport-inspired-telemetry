terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "s3" {
    # Configure backend per environment
    # bucket         = "f1-telemetry-terraform-state"
    # key            = "terraform.tfstate"
    # region         = "us-east-1"
    # encrypt        = true
    # dynamodb_table = "f1-telemetry-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  azs          = data.aws_availability_zones.available.names
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name    = var.project_name
  environment     = var.environment
  eks_cluster_arn = module.eks.cluster_arn
  oidc_provider   = module.eks.oidc_provider
  s3_bucket_arns  = module.s3.bucket_arns
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name          = var.project_name
  environment           = var.environment
  cluster_version       = var.eks_cluster_version
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  node_instance_types   = var.eks_node_instance_types
  node_desired_capacity = var.eks_node_desired_capacity
  node_min_capacity     = var.eks_node_min_capacity
  node_max_capacity     = var.eks_node_max_capacity
}
