# Asymmetric ECC key — required by cosign for sign/verify operations.
# KMS handles the private key; we never export it.
resource "aws_kms_key" "cosign" {
  description              = "${var.project_name} cosign image-signing key"
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  enable_key_rotation      = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "RootAccess"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action   = "kms:*"
      Resource = "*"
    }]
  })
}

resource "aws_kms_alias" "cosign" {
  name          = "alias/${var.project_name}-cosign"
  target_key_id = aws_kms_key.cosign.key_id
}
