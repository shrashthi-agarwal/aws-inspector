## IAM role for cloudwatch event to schedule inspector run ##

resource "aws_iam_role" "inspector" {
  name = "inspector-role"

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
  name = "inspector-policy"
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

## This will create resource group to help identify tags ##


resource "aws_inspector_resource_group" "resource" {
  tags = {
    Name = "${var.tag}"
  }
}

## Create assessment target ##


resource "aws_inspector_assessment_target" "Inspectortarget" {
  name               = "Inspector-target"
  resource_group_arn = "${aws_inspector_resource_group.resource.arn}"
}

## Create assessment template ##


resource "aws_inspector_assessment_template" "Inspectortemplate" {

  name       = "Inspector-template"

  target_arn = "${aws_inspector_assessment_target.Inspectortarget.arn}"

  duration   = 900

  rules_package_arns = [

    "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-gEjTy7T7"

  ]

}

resource "aws_cloudwatch_event_rule" "schedulerun" {
    name = "inspector-scan"
    description = "Fires once in a month"
    schedule_expression = "${var.cron}"
}

resource "aws_cloudwatch_event_target" "check_inspector" {
    rule = "${aws_cloudwatch_event_rule.schedulerun.name}"
    role_arn = "${aws_iam_role.inspector.arn}"
    arn = "${aws_inspector_assessment_template.Inspectortemplate.arn}"
}


