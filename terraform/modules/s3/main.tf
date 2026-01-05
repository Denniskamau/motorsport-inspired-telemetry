# S3 Bucket for Raw Telemetry
resource "aws_s3_bucket" "raw_telemetry" {
  bucket = "${var.project_name}-${var.environment}-raw-telemetry"

  tags = {
    Name        = "${var.project_name}-${var.environment}-raw-telemetry"
    DataType    = "raw"
    Description = "Raw F1 telemetry data from edge devices"
  }
}

resource "aws_s3_bucket_versioning" "raw_telemetry" {
  bucket = aws_s3_bucket.raw_telemetry.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_telemetry" {
  bucket = aws_s3_bucket.raw_telemetry.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "raw_telemetry" {
  bucket = aws_s3_bucket.raw_telemetry.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw_telemetry" {
  bucket = aws_s3_bucket.raw_telemetry.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for Processed Telemetry
resource "aws_s3_bucket" "processed_telemetry" {
  bucket = "${var.project_name}-${var.environment}-processed-telemetry"

  tags = {
    Name        = "${var.project_name}-${var.environment}-processed-telemetry"
    DataType    = "processed"
    Description = "Processed and analyzed F1 telemetry data"
  }
}

resource "aws_s3_bucket_versioning" "processed_telemetry" {
  bucket = aws_s3_bucket.processed_telemetry.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed_telemetry" {
  bucket = aws_s3_bucket.processed_telemetry.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "processed_telemetry" {
  bucket = aws_s3_bucket.processed_telemetry.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "processed_telemetry" {
  bucket = aws_s3_bucket.processed_telemetry.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for Athena Query Results
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-${var.environment}-athena-results"

  tags = {
    Name        = "${var.project_name}-${var.environment}-athena-results"
    Description = "Athena query results"
  }
}

resource "aws_s3_bucket_versioning" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "cleanup-old-results"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
