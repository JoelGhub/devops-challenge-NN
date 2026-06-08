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

  # ── Stage 1: Source ──────────────────────────────────────────────────────────
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
        PollForSourceChanges = "false"  # EventBridge rule handles the trigger
      }
    }
  }

  # ── Stage 2: Build — Maven + Docker + ECR push ───────────────────────────────
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

  # ── Stage 3: Scan — Trivy CRITICAL gate ──────────────────────────────────────
  # SourceOutput is primary ($CODEBUILD_SRC_DIR); BuildOutput is secondary
  # ($CODEBUILD_SRC_DIR_BuildOutput) — required by buildspec-scan.yml
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
        ProjectName          = aws_codebuild_project.ci["scan"].name
        PrimarySource        = "SourceOutput"
      }
    }
  }

  # ── Stage 4: Sign — cosign + KMS key → ECR OCI signature artifact ────────────
  # SourceOutput is primary; ScanOutput is secondary
  # ($CODEBUILD_SRC_DIR_ScanOutput) — required by buildspec-sign-push.yml
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
}
