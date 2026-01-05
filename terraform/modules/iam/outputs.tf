output "ingestion_service_role_arn" {
  description = "IAM role ARN for ingestion service"
  value       = aws_iam_role.ingestion_service.arn
}

output "ingestion_service_role_name" {
  description = "IAM role name for ingestion service"
  value       = aws_iam_role.ingestion_service.name
}

output "glue_role_arn" {
  description = "IAM role ARN for Glue"
  value       = aws_iam_role.glue.arn
}

output "glue_role_name" {
  description = "IAM role name for Glue"
  value       = aws_iam_role.glue.name
}

output "athena_role_arn" {
  description = "IAM role ARN for Athena"
  value       = aws_iam_role.athena.arn
}

output "athena_role_name" {
  description = "IAM role name for Athena"
  value       = aws_iam_role.athena.name
}
