resource "random_id" "broker_vm_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "broker_vm" {
  bucket = "${var.name_prefix}-broker-vm-${random_id.broker_vm_suffix.hex}"
  force_destroy = true
  
  tags = merge(
    var.global_tags,
    {
      Name = "${var.name_prefix}-broker-vm"
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "broker_vm" {
  bucket = aws_s3_bucket.broker_vm.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "broker_vm" {
  bucket = aws_s3_bucket.broker_vm.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "vmimport" {
  name = "vmimport"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vmie.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:Externalid" = "vmimport"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vmimport" {
  name = "vmimport"
  role = aws_iam_role.vmimport.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.broker_vm.arn,
          "${aws_s3_bucket.broker_vm.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.broker_vm.arn,
          "${aws_s3_bucket.broker_vm.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:ModifySnapshotAttribute",
          "ec2:CopySnapshot",
          "ec2:RegisterImage",
          "ec2:Describe*",
          "ec2:ImportSnapshot",
          "ec2:DescribeImportSnapshotTasks"
        ]
        Resource = "*"
      }
    ]
  })
}