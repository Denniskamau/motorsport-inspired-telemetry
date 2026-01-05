# Extract OIDC provider URL
locals {
  oidc_provider_url = replace(var.oidc_provider, "https://", "")
}

# IAM Role for Ingestion Service (IRSA)
resource "aws_iam_role" "ingestion_service" {
  name = "${var.project_name}-${var.environment}-ingestion-service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url}:sub" = "system:serviceaccount:default:ingestion-service"
            "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ingestion-service"
    ServiceType = "ingestion"
  }
}

# IAM Policy for Ingestion Service S3 Access
resource "aws_iam_policy" "ingestion_service_s3" {
  name        = "${var.project_name}-${var.environment}-ingestion-service-s3"
  description = "Allows ingestion service to write to S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = flatten([
          for arn in var.s3_bucket_arns : [
            arn,
            "${arn}/*"
          ]
        ])
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ingestion_service_s3" {
  role       = aws_iam_role.ingestion_service.name
  policy_arn = aws_iam_policy.ingestion_service_s3.arn
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_policy" "ingestion_service_logs" {
  name        = "${var.project_name}-${var.environment}-ingestion-service-logs"
  description = "Allows ingestion service to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/eks/${var.project_name}-${var.environment}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ingestion_service_logs" {
  role       = aws_iam_role.ingestion_service.name
  policy_arn = aws_iam_policy.ingestion_service_logs.arn
}

# IAM Role for Glue
resource "aws_iam_role" "glue" {
  name = "${var.project_name}-${var.environment}-glue"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-glue"
  }
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# IAM Policy for Glue S3 Access
resource "aws_iam_policy" "glue_s3" {
  name        = "${var.project_name}-${var.environment}-glue-s3"
  description = "Allows Glue to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = flatten([
          for arn in var.s3_bucket_arns : [
            arn,
            "${arn}/*"
          ]
        ])
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3" {
  role       = aws_iam_role.glue.name
  policy_arn = aws_iam_policy.glue_s3.arn
}

# IAM Role for Athena
resource "aws_iam_role" "athena" {
  name = "${var.project_name}-${var.environment}-athena"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-athena"
  }
}

# IAM Policy for Athena S3 Access
resource "aws_iam_policy" "athena_s3" {
  name        = "${var.project_name}-${var.environment}-athena-s3"
  description = "Allows Athena to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:PutObject"
        ]
        Resource = flatten([
          for arn in var.s3_bucket_arns : [
            arn,
            "${arn}/*"
          ]
        ])
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "athena_s3" {
  role       = aws_iam_role.athena.name
  policy_arn = aws_iam_policy.athena_s3.arn
}
