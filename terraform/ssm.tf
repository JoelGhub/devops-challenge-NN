# Pre-seed parameters that the build/scan/sign buildspecs read at runtime

resource "aws_ssm_parameter" "ecr_repo_uri" {
  name  = "/devops/ecr/repo-uri"
  type  = "String"
  value = aws_ecr_repository.app.repository_url
}

resource "aws_ssm_parameter" "ecr_registry" {
  name  = "/devops/ecr/registry"
  type  = "String"
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# Paths match exactly what buildspec-sign-push.yml reads
resource "aws_ssm_parameter" "kms_cosign_arn" {
  name  = "/devops/cosign/kms-key-arn"
  type  = "String"
  value = aws_kms_key.cosign.arn
}

resource "aws_ssm_parameter" "kms_cosign_alias" {
  name  = "/devops/cosign/kms-key-alias"
  type  = "String"
  value = aws_kms_alias.cosign.name
}
