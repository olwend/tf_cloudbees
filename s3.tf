
resource "aws_s3_bucket" "binaries" {
  bucket = "mpesa-artifacts-${data.aws_caller_identity.current.account_id}-eu-west-1-cps-binaries"

  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = var.s3_logging_bucket
    target_prefix = "${var.ProjectName}-binaries/"
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "Binaries for CloudBees CD",
      "SecurityZone", "X2"
    )
  )}"
}

resource "aws_s3_bucket_policy" "cps-bucket-policy" {

  bucket = "${aws_s3_bucket.binaries.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:ListBucketMultipartUploads"
                ],
      "Resource": [
        "${aws_s3_bucket.binaries.arn}",
        "${aws_s3_bucket.binaries.arn}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}

###Add s3 bucket for storing files from local
resource "aws_s3_bucket" "s3bktlocal" {
  bucket = "mpesa-artifacts-${data.aws_caller_identity.current.account_id}-eu-west-1-bkt-local"

  acl           = "private"
  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = var.s3_logging_bucket
    target_prefix = "${var.ProjectName}-s3local/"
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Purpose", "Store all files for CPS automation project from local",
      "SecurityZone", "X2"
    )
  )}"
}
resource "aws_s3_bucket_policy" "s3bktlocal-bucket-ssl-policy" {

  bucket = "${aws_s3_bucket.s3bktlocal.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:ListBucketMultipartUploads",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion",
                "s3:DeleteBucket"
                ],
      "Resource": [
        "${aws_s3_bucket.s3bktlocal.arn}",
        "${aws_s3_bucket.s3bktlocal.arn}/*"
      ]
    }
  ]
}
POLICY
}