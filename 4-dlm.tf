resource "aws_iam_role" "dlm_lifecycle_role" {
  name = "${var.ProjectName}-dlm-lifecycle-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "dlm.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
  EOF
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name = "${var.ProjectName}-dlm-lifecycle-policy"
  role = aws_iam_role.dlm_lifecycle_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Effect": "Allow",
          "Action": [
              "ec2:CreateSnapshot",
              "ec2:DeleteSnapshot",
              "ec2:DescribeVolumes",
              "ec2:DescribeSnapshots"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
              "ec2:CreateTags"
          ],
          "Resource": "arn:aws:ec2:*::snapshot/*"
        }
    ]
  }
  EOF
}

/*resource "aws_cloudformation_stack" "dlm" {
    name = "${var.ProjectName}-dlm-policy-stack"
    template_body = "${file("${path.module}/4-dlm.yml")}"

    parameters {
      ProjectName = "${var.ProjectName}"
      ExecRoleArn = "${aws_iam_role.dlm_lifecycle_role.arn}"
    }

    tags = "${merge(    
      local.common_tags,
      map(
        "Purpose", "DLM Policy stack for ${var.ProjectName}",
        "SecurityZone", "X2"
      )
    )}"
  }
*/
resource "aws_dlm_lifecycle_policy" "dlm" {
  description        = "DLM lifecycle policy for CPS instances"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "2 days of daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["23:00"]
      }

      retain_rule {
        count = 2
      }

      copy_tags = true
    }

    target_tags = {
      DLMBackup = "true"
    }
  }
}
