resource "aws_sns_topic" "approvals" {
  name = "${var.project_name}-approvals"
}

resource "aws_sns_topic_subscription" "approvals_email" {
  count     = var.approval_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.approvals.arn
  protocol  = "email"
  endpoint  = var.approval_email
}
