#!/usr/bin/env bash
# =============================================================
# install-tools.sh
# Installs kubectl, Helm, and cosign inside a CodeBuild container.
# Called at the start of every deploy buildspec.
#
# Expected env vars (set in CodeBuild project):
#   COSIGN_VERSION  e.g. v2.2.4
#   HELM_VERSION    e.g. 3.14.0
# =============================================================
set -euo pipefail

COSIGN_VERSION="${COSIGN_VERSION:-v2.2.4}"
HELM_VERSION="${HELM_VERSION:-3.14.0}"

echo "──────────────────────────────────────────────────────"
echo " Installing pipeline tools"
echo "  cosign : $COSIGN_VERSION"
echo "  Helm   : $HELM_VERSION"
echo "  kubectl: stable"
echo "──────────────────────────────────────────────────────"

# ── kubectl ──────────────────────────────────────────────────
if ! command -v kubectl &>/dev/null; then
  echo "[+] Installing kubectl..."
  K8S_STABLE=$(curl -sSL https://dl.k8s.io/release/stable.txt)
  curl -sSfLO "https://dl.k8s.io/release/${K8S_STABLE}/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl
fi
kubectl version --client
echo "kubectl installed."

# ── Helm ─────────────────────────────────────────────────────
if ! command -v helm &>/dev/null; then
  echo "[+] Installing Helm $HELM_VERSION..."
  curl -sSfL \
    "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
    | tar -xz -C /tmp
  install -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm
  rm -rf /tmp/linux-amd64
fi
helm version
echo "Helm installed."

# ── cosign ───────────────────────────────────────────────────
if ! command -v cosign &>/dev/null; then
  echo "[+] Installing cosign $COSIGN_VERSION..."
  curl -sSfLO \
    "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
  install -m 0755 cosign-linux-amd64 /usr/local/bin/cosign
  rm -f cosign-linux-amd64
fi
cosign version
echo "cosign installed."

echo "──────────────────────────────────────────────────────"
echo " All tools ready."
echo "──────────────────────────────────────────────────────"
