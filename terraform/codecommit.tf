resource "aws_codecommit_repository" "app" {
  repository_name = var.codecommit_repo_name
  description     = "${var.project_name} application source"
  default_branch  = var.branch_name
}

# EventBridge rule — triggers the pipeline on every push to the tracked branch
resource "aws_cloudwatch_event_rule" "codecommit_push" {
  name        = "${var.project_name}-on-push"
  description = "Trigger CodePipeline when ${var.branch_name} is updated"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = [aws_codecommit_repository.app.arn]
    detail = {
      event         = ["referenceUpdated"]
      referenceType = ["branch"]
      referenceName = [var.branch_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "pipeline" {
  rule     = aws_cloudwatch_event_rule.codecommit_push.name
  arn      = aws_codepipeline.main.arn
  role_arn = aws_iam_role.events_codepipeline.arn
}

# EventBridge needs permission to start the pipeline
resource "aws_iam_role" "events_codepipeline" {
  name = "${var.project_name}-events-pipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "events_codepipeline" {
  name = "start-pipeline"
  role = aws_iam_role.events_codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["codepipeline:StartPipelineExecution"]
      Resource = aws_codepipeline.main.arn
    }]
  })
}
