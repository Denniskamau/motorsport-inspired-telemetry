variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "f1-telemetry"
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "owner" {
  description = "Project owner/team"
  type        = string
  default     = "platform-engineering"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_capacity" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_capacity" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_capacity" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 5
}
