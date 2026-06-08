resource "aws_codepipeline" "main" {
  name     = var.project_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifacts.bucket

    encryption_key {
      id   = aws_kms_key.artifacts.arn
      type = "KMS"
    }
  }

  # ── 1. Source ────────────────────────────────────────────────
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceOutput"]
      configuration = {
        RepositoryName       = aws_codecommit_repository.app.repository_name
        BranchName           = var.branch_name
        PollForSourceChanges = "false"
      }
    }
  }

  # ── 2. Build ─────────────────────────────────────────────────
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      configuration = {
        ProjectName = aws_codebuild_project.ci["build"].name
      }
    }
  }

  # ── 3. Scan (Trivy) ───────────────────────────────────────────
  stage {
    name = "Scan"
    action {
      name             = "TrivyScan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput", "BuildOutput"]
      output_artifacts = ["ScanOutput"]
      configuration = {
        ProjectName   = aws_codebuild_project.ci["scan"].name
        PrimarySource = "SourceOutput"
      }
    }
  }

  # ── 4. Sign (cosign + KMS) ────────────────────────────────────
  stage {
    name = "Sign"
    action {
      name             = "SignAndPush"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput", "ScanOutput"]
      output_artifacts = ["SignedOutput"]
      configuration = {
        ProjectName   = aws_codebuild_project.ci["sign-push"].name
        PrimarySource = "SourceOutput"
      }
    }
  }

  # ── 5. Deploy Dev (simulated) ─────────────────────────────────
  stage {
    name = "DeployDev"
    action {
      name            = "DeployDev"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput", "SignedOutput"]
      configuration = {
        ProjectName   = aws_codebuild_project.deploy["deploy-dev"].name
        PrimarySource = "SourceOutput"
      }
    }
  }

  # ── 6. Approval: Dev → Staging ────────────────────────────────
  stage {
    name = "ApproveStaging"
    action {
      name     = "ApproveStaging"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
      configuration = {
        NotificationArn = aws_sns_topic.approvals.arn
        CustomData      = "Dev OK? Approve to promote to Staging."
      }
    }
  }

  # ── 7. Deploy Staging (simulated) ────────────────────────────
  stage {
    name = "DeployStaging"
    action {
      name            = "DeployStaging"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput", "SignedOutput"]
      configuration = {
        ProjectName   = aws_codebuild_project.deploy["deploy-staging"].name
        PrimarySource = "SourceOutput"
      }
    }
  }

  # ── 8. Approval: Staging → Prod ───────────────────────────────
  stage {
    name = "ApproveProd"
    action {
      name     = "ApproveProd"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
      configuration = {
        NotificationArn = aws_sns_topic.approvals.arn
        CustomData      = "Staging OK? Approve to promote to Production."
      }
    }
  }

  # ── 9. Deploy Prod (simulated) ────────────────────────────────
  stage {
    name = "DeployProd"
    action {
      name            = "DeployProd"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput", "SignedOutput"]
      configuration = {
        ProjectName   = aws_codebuild_project.deploy["deploy-prod"].name
        PrimarySource = "SourceOutput"
      }
    }
  }
}
