variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "eks_cluster_arn" {
  description = "EKS cluster ARN"
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider ARN"
  type        = string
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs"
  type        = list(string)
}
