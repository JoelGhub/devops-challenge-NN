locals {
  ci_stages = {
    build     = { buildspec = "buildspecs/buildspec-build.yml",    extra_env = {} }
    scan      = { buildspec = "buildspecs/buildspec-scan.yml",     extra_env = {} }
    sign-push = { buildspec = "buildspecs/buildspec-sign-push.yml", extra_env = {
      # COSIGN_VERSION is used in the install phase of the buildspec
      COSIGN_VERSION = "v2.2.4"
    }}
  }
}

resource "aws_codebuild_project" "ci" {
  for_each     = local.ci_stages
  name         = "${var.project_name}-${each.key}"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:7.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true  # Required for Docker daemon (build + scan stages)

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
