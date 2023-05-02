resource "aws_iam_policy" "mpesa-cps-flow-instance-role-policy" {
  name        = "${var.ProjectName}-instance-role-policy"
  path        = "/"
  description = "Allows an instance to forward logs to CloudWatch, s3 and SSM"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObjectAcl",
                "s3:GetEncryptionConfiguration"
            ],
            "Resource": [
                "arn:aws:s3:::mpesa-${data.aws_caller_identity.current.account_id}-logs",
                "arn:aws:s3:::mpesa-${data.aws_caller_identity.current.account_id}-logs/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:GetManifest",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ds:CreateComputer",
                "ds:DescribeDirectories"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts",
                "arn:aws:s3:::mpesa-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-start-up-scripts/*",
                "arn:aws:s3:::mpesa-artifacts-${data.aws_caller_identity.current.account_id}-eu-west-1-bkt-local",
                "arn:aws:s3:::mpesa-artifacts-${data.aws_caller_identity.current.account_id}-eu-west-1-bkt-local/*",
                "arn:aws:s3:::mpesa-artifacts-${data.aws_caller_identity.current.account_id}-eu-west-1-cps-binaries",
                "arn:aws:s3:::mpesa-artifacts-${data.aws_caller_identity.current.account_id}-eu-west-1-cps-binaries/*"

            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetEncryptionConfiguration",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": [
                "arn:aws:s3:::aws-ssm-${data.aws_region.current.name}/*",
                "arn:aws:s3:::aws-windows-downloads-${data.aws_region.current.name}/*",
                "arn:aws:s3:::amazon-ssm-${data.aws_region.current.name}/*",
                "arn:aws:s3:::amazon-ssm-packages-${data.aws_region.current.name}/*",
                "arn:aws:s3:::${data.aws_region.current.name}-birdwatcher-prod/*",
                "arn:aws:s3:::patch-baseline-snapshot-${data.aws_region.current.name}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "mpesa-cps-flow-instance-role" {
  name = "${var.ProjectName}-instance-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "mpesa-cps-role-policy-attach" {
  name = "${var.ProjectName}-role-policy-attach"
  roles = [
    "${aws_iam_role.mpesa-cps-flow-instance-role.name}",
    "${aws_iam_role.mpesa-cb-core-instance-role.name}"
  ]
  policy_arn = "${aws_iam_policy.mpesa-cps-flow-instance-role-policy.arn}"
}

resource "aws_iam_instance_profile" "mpesa-cps-instance-profile" {
  name = "${var.ProjectName}-flow-instance-profile"
  role = "${aws_iam_role.mpesa-cps-flow-instance-role.name}"
}

data "aws_iam_policy_document" "mpesa-cps-flow-download-binaries" {
  statement {
    actions = [
      "s3:List*",
      "s3:Get*",
      "s3:Put*", // Allow uploading initial binaries
    ]

    resources = [
      aws_s3_bucket.binaries.arn,
      "${aws_s3_bucket.binaries.arn}/*",
    ]

  }

  statement {
    actions = [
      "ec2:DescribeTags",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "mpesa-cps-flow-download-binaries" {
  name   = "${var.ProjectName}-flow-download-binaries"
  role   = aws_iam_role.mpesa-cps-flow-instance-role.id
  policy = data.aws_iam_policy_document.mpesa-cps-flow-download-binaries.json
}
