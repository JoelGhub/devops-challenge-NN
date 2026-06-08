output "codecommit_clone_url_https" {
  value       = aws_codecommit_repository.app.clone_url_http
  description = "HTTPS URL — add as git remote to push and trigger the pipeline"
}

output "codecommit_clone_url_ssh" {
  value       = aws_codecommit_repository.app.clone_url_ssh
  description = "SSH URL — add as git remote to push and trigger the pipeline"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR repository where Docker images are pushed by the Build stage"
}

output "kms_cosign_key_arn" {
  value       = aws_kms_key.cosign.arn
  description = "KMS key ARN used by cosign to sign images in the Sign stage"
}

output "s3_artifacts_bucket" {
  value       = aws_s3_bucket.artifacts.bucket
  description = "S3 bucket that stores pipeline artifacts between stages"
}

output "pipeline_console_url" {
  value       = "https://${var.aws_region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${var.project_name}/view"
  description = "Direct link to watch the pipeline run in the AWS Console"
}

output "instructions" {
  value = <<-EOT

    ┌─────────────────────────────────────────────────┐
    │  Pipeline ready. To run it:                     │
    │                                                 │
    │  1. Add CodeCommit as a git remote:             │
    │     git remote add aws <codecommit_https_url>   │
    │                                                 │
    │  2. Push your code (triggers pipeline):         │
    │     git push aws main                           │
    │                                                 │
    │  3. Watch it in the AWS Console:                │
    │     <pipeline_console_url>                      │
    │                                                 │
    │  4. Tear down everything when done:             │
    │     terraform destroy                           │
    └─────────────────────────────────────────────────┘
  EOT
  description = "Quick-start instructions"
}
