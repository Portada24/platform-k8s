#!/usr/bin/env bash
# Instala ArgoCD (Helm), registra el repo privado y aplica la Application raíz.
# Requiere: GIT_REPO_URL y GIT_TOKEN (PAT de solo lectura) en el entorno. El token NO se guarda en el repo.
set -euo pipefail
cd "$(dirname "$0")/.."
source versions.env
: "${GIT_REPO_URL:?define GIT_REPO_URL}"
: "${GIT_TOKEN:?define GIT_TOKEN}"
GIT_USER="${GIT_USER:-git}"

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update >/dev/null
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace \
  --version "${ARGOCD_CHART_VERSION}" -f bootstrap/argocd/values.yaml --wait --timeout 10m

# Credencial del repositorio privado (secreto creado en runtime, nunca versionado)
kubectl -n argocd create secret generic repo-platform-k8s \
  --from-literal=type=git --from-literal=url="$GIT_REPO_URL" \
  --from-literal=username="$GIT_USER" --from-literal=password="$GIT_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd label secret repo-platform-k8s argocd.argoproj.io/secret-type=repository --overwrite

kubectl apply -f bootstrap/root-app.yaml
echo "Application raíz aplicada. Password admin inicial:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
