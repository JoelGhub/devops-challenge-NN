locals {
  ci_stages = {
    build     = { buildspec = "buildspecs/buildspec-build.yml",     extra_env = {} }
    scan      = { buildspec = "buildspecs/buildspec-scan.yml",      extra_env = {} }
    sign-push = { buildspec = "buildspecs/buildspec-sign-push.yml", extra_env = {
      COSIGN_VERSION = "v2.2.4"
    }}
  }

  deploy_stages = {
    deploy-dev     = { buildspec = "buildspecs/buildspec-deploy-dev.yml" }
    deploy-staging = { buildspec = "buildspecs/buildspec-deploy-staging.yml" }
    deploy-prod    = { buildspec = "buildspecs/buildspec-deploy-prod.yml" }
  }
}

resource "aws_codebuild_project" "ci" {
  for_each     = local.ci_stages
  name         = "${var.project_name}-${each.key}"
  service_role = aws_iam_role.codebuild.arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:7.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    dynamic "environment_variable" {
      for_each = each.value.extra_env
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = each.value.buildspec
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = each.key
    }
  }
}

resource "aws_codebuild_project" "deploy" {
  for_each     = local.deploy_stages
  name         = "${var.project_name}-${each.key}"
  service_role = aws_iam_role.codebuild.arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:7.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = false

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = each.value.buildspec
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = each.key
    }
  }
}
