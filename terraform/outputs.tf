output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_oidc_provider" {
  description = "EKS OIDC provider"
  value       = module.eks.oidc_provider
}

output "s3_raw_telemetry_bucket" {
  description = "S3 bucket for raw telemetry"
  value       = module.s3.raw_telemetry_bucket
}

output "s3_processed_telemetry_bucket" {
  description = "S3 bucket for processed telemetry"
  value       = module.s3.processed_telemetry_bucket
}

output "ingestion_service_role_arn" {
  description = "IAM role ARN for ingestion service"
  value       = module.iam.ingestion_service_role_arn
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
