resource "aws_iam_policy" "mpesa-cb-core-instance-role-policy" {
  name        = "${var.ProjectName}-core-instance-role-policy"
  path        = "/"
  description = "Allows an instance to create packer images"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "PackerIAMCreateRole",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:GetRole",
                "iam:GetInstanceProfile",
                "iam:DeleteRolePolicy",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:PutRolePolicy",
                "iam:AddRoleToInstanceProfile"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "mpesa-cb-core-instance-role" {
  name = "${var.ProjectName}-core-instance-role"

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

resource "aws_iam_policy_attachment" "mpesa-cb-core-role-policy-attach" {
  name       = "${var.ProjectName}-cb-core-policy-attach"
  roles      = ["${aws_iam_role.mpesa-cb-core-instance-role.name}"]
  policy_arn = "${aws_iam_policy.mpesa-cb-core-instance-role-policy.arn}"
}

resource "aws_iam_instance_profile" "mpesa-cb-core-instance-profile" {
  name = "${var.ProjectName}-db-core-instance-profile"
  role = "${aws_iam_role.mpesa-cb-core-instance-role.name}"
}

### ASSUMED ROLE ###
resource "aws_iam_policy" "mpesa-cb-core-packer-instance-role-policy" {
  name        = "${var.ProjectName}-core-packer-instance-role-policy"
  path        = "/"
  description = "Allows an instance to create packer images"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CopyImage",
                "ec2:CreateImage",
                "ec2:CreateKeypair",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSnapshot",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:DeleteKeyPair",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteSnapshot",
                "ec2:DeleteVolume",
                "ec2:DeregisterImage",
                "ec2:DescribeImageAttribute",
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeRegions",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DetachVolume",
                "ec2:GetPasswordData",
                "ec2:ModifyImageAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:ModifySnapshotAttribute",
                "ec2:RegisterImage",
                "ec2:RunInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeVpcs"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "PackerIAMCreateRole",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:GetRole",
                "iam:GetInstanceProfile",
                "iam:DeleteRolePolicy",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:PutRolePolicy",
                "iam:AddRoleToInstanceProfile",
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*"
        },
        {
            "Sid": "PackerSpotRole",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateLaunchTemplate",
                "ec2:DeleteLaunchTemplate",
                "ec2:CreateFleet",
                "ec2:DescribeSpotPriceHistory"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "mpesa-cb-core-packer-instance-role" {
  name = "${var.ProjectName}-core-packer-instance-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                ]
            },
            "Action": "sts:AssumeRole",
            "Condition": {"StringEquals": {"sts:ExternalId": "ECSD"}}
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "mpesa-cb-core-packer-role-policy-attach" {
  name       = "${var.ProjectName}-cb-core-packer-policy-attach"
  roles      = ["${aws_iam_role.mpesa-cb-core-packer-instance-role.name}"]
  policy_arn = "${aws_iam_policy.mpesa-cb-core-packer-instance-role-policy.arn}"
}