#!/usr/bin/env bash
# Ejecutar en cada worker:  K3S_URL=https://<ip-control-plane>:6443 K3S_TOKEN=<token> ./scripts/11-k3s-agent.sh
set -euo pipefail
cd "$(dirname "$0")/.."
source versions.env
: "${K3S_URL:?define K3S_URL}"
: "${K3S_TOKEN:?define K3S_TOKEN}"

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${K3S_VERSION}" K3S_URL="$K3S_URL" K3S_TOKEN="$K3S_TOKEN" sh -s - agent
