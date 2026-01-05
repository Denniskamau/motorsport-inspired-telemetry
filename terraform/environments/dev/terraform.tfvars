aws_region  = "us-east-1"
environment = "dev"

# VPC
vpc_cidr = "10.0.0.0/16"

# EKS
eks_cluster_version       = "1.28"
eks_node_instance_types   = ["t3.medium"]
eks_node_desired_capacity = 2
eks_node_min_capacity     = 1
eks_node_max_capacity     = 3
