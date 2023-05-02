resource "aws_iam_role" "inspector" {
  name = "${var.ProjectName}-inspector-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "inspector" {
  name_prefix = "${var.ProjectName}-cloudwatch-event-inspector-${var.ENV}"
  role        = "${aws_iam_role.inspector.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "inspector:StartAssessmentRun"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_inspector_assessment_template" "inspector" {
  name       = " MPesa CPS inspector assessment template"
  target_arn = "${aws_inspector_assessment_target.inspector.arn}"
  duration   = 3600

  rules_package_arns = [
    "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-ubA5XvBh",
    "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-sJBhCr0F",
    "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-SPzU33xe",
    "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-SnojL3Z6"
  ]
}

resource "aws_inspector_assessment_target" "inspector" {
  name = "MPesa CPS inspector assessment target"
}

resource "aws_cloudwatch_event_rule" "inspector" {
  name                = "${var.ProjectName}-aws-inspector-run-${var.ENV}"
  description         = "MPesa CPS AWS Inspector run for ${var.ENV}"
  schedule_expression = "cron(0 13 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "inspector" {
  rule     = "${aws_cloudwatch_event_rule.inspector.name}"
  arn      = "${aws_inspector_assessment_template.inspector.arn}"
  role_arn = "${aws_iam_role.inspector.arn}"
}