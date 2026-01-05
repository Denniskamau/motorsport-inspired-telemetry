output "raw_telemetry_bucket" {
  description = "Raw telemetry S3 bucket name"
  value       = aws_s3_bucket.raw_telemetry.id
}

output "raw_telemetry_bucket_arn" {
  description = "Raw telemetry S3 bucket ARN"
  value       = aws_s3_bucket.raw_telemetry.arn
}

output "processed_telemetry_bucket" {
  description = "Processed telemetry S3 bucket name"
  value       = aws_s3_bucket.processed_telemetry.id
}

output "processed_telemetry_bucket_arn" {
  description = "Processed telemetry S3 bucket ARN"
  value       = aws_s3_bucket.processed_telemetry.arn
}

output "athena_results_bucket" {
  description = "Athena results S3 bucket name"
  value       = aws_s3_bucket.athena_results.id
}

output "athena_results_bucket_arn" {
  description = "Athena results S3 bucket ARN"
  value       = aws_s3_bucket.athena_results.arn
}

output "bucket_arns" {
  description = "All S3 bucket ARNs"
  value = [
    aws_s3_bucket.raw_telemetry.arn,
    aws_s3_bucket.processed_telemetry.arn,
    aws_s3_bucket.athena_results.arn
  ]
}
