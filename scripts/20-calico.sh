#!/usr/bin/env bash
# Instala Calico (CNI) y espera a que todos los nodos estén Ready.
set -euo pipefail
cd "$(dirname "$0")/.."
source versions.env

kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml" \
  || kubectl replace -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"

kubectl wait --for=condition=Established crd/installations.operator.tigera.io --timeout=120s
kubectl apply -f bootstrap/calico/installation.yaml

echo "Esperando a que los nodos estén Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s
kubectl get nodes -o wide
