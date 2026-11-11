#!/usr/bin/env bash
# Ejecutar en el nodo control-plane. Requiere haber editado bootstrap/k3s/server-config.yaml (tls-san).
set -euo pipefail
cd "$(dirname "$0")/.."
source versions.env

if grep -q CHANGE_ME bootstrap/k3s/server-config.yaml; then
  echo "Edita bootstrap/k3s/server-config.yaml (tls-san) antes de continuar" >&2; exit 1
fi

sudo mkdir -p /etc/rancher/k3s
sudo cp bootstrap/k3s/server-config.yaml /etc/rancher/k3s/config.yaml

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${K3S_VERSION}" sh -s - server

echo "Token para unir workers (guárdalo fuera del repo):"
sudo cat /var/lib/rancher/k3s/server/node-token
echo "Kubeconfig: /etc/rancher/k3s/k3s.yaml  (copiar a ~/.kube/config y cambiar 127.0.0.1 por la IP del servidor)"
echo "Los nodos quedarán NotReady hasta instalar Calico: make cluster"
