#!/usr/bin/env bash
# =============================================================
# verify-image.sh
# Verifies the cosign signature of a Docker image stored in ECR.
# Called in every deploy stage BEFORE kubectl/Helm runs.
#
# Usage:
#   ./verify-image.sh <image-uri-with-digest> <kms-key-arn>
#
# Example:
#   ./verify-image.sh \
#     "123456789012.dkr.ecr.us-east-1.amazonaws.com/springboot-app@sha256:abc123..." \
#     "arn:aws:kms:us-east-1:123456789012:key/mrk-xxxxxxxx"
#
# Exit codes:
#   0  – signature valid
#   1  – signature invalid / not found → DEPLOYMENT MUST BE BLOCKED
# =============================================================
set -euo pipefail

IMAGE_REF="${1:?Usage: verify-image.sh <image-ref> <kms-key-arn>}"
KMS_KEY_ARN="${2:?Usage: verify-image.sh <image-ref> <kms-key-arn>}"

echo "──────────────────────────────────────────────────────"
echo " Verifying cosign signature"
echo "  Image  : $IMAGE_REF"
echo "  KMS Key: $KMS_KEY_ARN"
echo "──────────────────────────────────────────────────────"

if ! command -v cosign &>/dev/null; then
  echo "[ERROR] cosign not found in PATH"
  exit 1
fi

if [[ "$IMAGE_REF" != *"@sha256:"* ]]; then
  echo "[ERROR] Must use digest reference (@sha256:...) – not a tag alone."
  exit 1
fi

# ECR login
ECR_REGISTRY=$(echo "$IMAGE_REF" | cut -d/ -f1)
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
echo "[+] Logging in to ECR: $ECR_REGISTRY"
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

# Verify
echo "[+] Verifying signature..."
if cosign verify \
    --key "awskms:///${KMS_KEY_ARN}" \
    --insecure-ignore-tlog=true \
    "$IMAGE_REF"; then

  echo ""
  echo "✅ Signature verification PASSED."
  echo "   Image is authentic and has not been tampered with."
  exit 0
else
  echo ""
  echo "##########################################################"
  echo "# ❌ SIGNATURE VERIFICATION FAILED                       #"
  echo "#    Image has NOT been signed by the CI pipeline.       #"
  echo "#    Deployment is BLOCKED for security reasons.         #"
  echo "##########################################################"
  exit 1
fi
