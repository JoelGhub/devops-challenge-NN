#!/usr/bin/env bash
# =============================================================
# sign-image.sh
# Signs a Docker image in ECR using cosign + AWS KMS.
#
# Usage:
#   ./sign-image.sh <image-uri-with-digest> <kms-key-arn>
#
# Example:
#   ./sign-image.sh \
#     "123456789012.dkr.ecr.us-east-1.amazonaws.com/springboot-app@sha256:abc123..." \
#     "arn:aws:kms:us-east-1:123456789012:key/mrk-xxxxxxxx"
#
# Requirements:
#   - cosign in PATH
#   - AWS credentials with kms:Sign, kms:GetPublicKey permissions
#   - Docker logged in to ECR
# =============================================================
set -euo pipefail

IMAGE_REF="${1:?Usage: sign-image.sh <image-ref> <kms-key-arn>}"
KMS_KEY_ARN="${2:?Usage: sign-image.sh <image-ref> <kms-key-arn>}"

echo "──────────────────────────────────────────────────────"
echo " Signing image with cosign (KMS)"
echo "  Image  : $IMAGE_REF"
echo "  KMS Key: $KMS_KEY_ARN"
echo "──────────────────────────────────────────────────────"

# Verify cosign is installed
if ! command -v cosign &>/dev/null; then
  echo "[ERROR] cosign not found in PATH"
  exit 1
fi

# Ensure the image reference includes a digest (not just a tag)
if [[ "$IMAGE_REF" != *"@sha256:"* ]]; then
  echo "[ERROR] image reference must include digest (@sha256:...) for tamper-proof signing."
  echo "        Use: <repo>@sha256:<digest>"
  exit 1
fi

# ECR login helper
ECR_REGISTRY=$(echo "$IMAGE_REF" | cut -d/ -f1)
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
echo "[+] Logging in to ECR: $ECR_REGISTRY"
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

# Sign
echo "[+] Signing..."
cosign sign \
  --key "awskms:///${KMS_KEY_ARN}" \
  --tlog-upload=false \
  "$IMAGE_REF"

echo ""
echo "✅ Image signed successfully."
echo "   Signature stored in ECR as OCI artifact."
echo "   Verify with:  ./scripts/verify-image.sh \"$IMAGE_REF\" \"$KMS_KEY_ARN\""
