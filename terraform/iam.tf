# ── CodePipeline Service Role ──────────────────────────────────────────────────
resource "aws_iam_role" "codepipeline" {
  name = "${var.project_name}-codepipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "main"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GetBranch", "codecommit:GetCommit",
          "codecommit:UploadArchive", "codecommit:GetUploadArchiveStatus",
          "codecommit:CancelUploadArchive"
        ]
        Resource = aws_codecommit_repository.app.arn
      },
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:GetObjectVersion",
          "s3:PutObject", "s3:GetBucketVersioning"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource = aws_kms_key.artifacts.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.approvals.arn
      }
    ]
  })
}

# ── CodeBuild Service Role ─────────────────────────────────────────────────────
resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "main"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CloudWatchLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },
      {
        Sid    = "S3Artifacts"
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:GetObjectVersion",
          "s3:PutObject", "s3:GetBucketVersioning", "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Sid      = "KMSArtifacts"
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey", "kms:Decrypt", "kms:Encrypt"]
        Resource = aws_kms_key.artifacts.arn
      },
      {
        Sid      = "ECRLogin"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRRepo"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage", "ecr:PutImage",
          "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload",
          "ecr:DescribeImages", "ecr:DescribeRepositories", "ecr:ListImages"
        ]
        Resource = aws_ecr_repository.app.arn
      },
      {
        Sid    = "KMSCosign"
        Effect = "Allow"
        Action = ["kms:Sign", "kms:Verify", "kms:GetPublicKey", "kms:DescribeKey"]
        Resource = aws_kms_key.cosign.arn
      },
      {
        Sid    = "SSMParams"
        Effect = "Allow"
        Action = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/devops/*"
      }
    ]
  })
}
