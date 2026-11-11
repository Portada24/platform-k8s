SHELL := /bin/bash
KUBECTL_WAIT = kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application
TIMEOUT ?= 20m

.PHONY: help set-repo cluster argocd infra gateway observability expose status

help:
	@echo "Pasos manuales previos (en los nodos): scripts/00-node-prereqs.sh, 10-k3s-server.sh, 11-k3s-agent.sh"
	@echo "Targets: set-repo REPO=<url> | cluster | argocd | infra | gateway | observability | expose | status"

# Reemplaza el placeholder del repo en todos los manifiestos. Uso: make set-repo REPO=https://github.com/usuario/platform-k8s.git
set-repo:
	@test -n "$(REPO)" || (echo "Falta REPO=<url>" && exit 1)
	grep -rl 'https://github.com/CHANGE_ME/platform-k8s.git' --include='*.yaml' . | xargs sed -i 's|https://github.com/CHANGE_ME/platform-k8s.git|$(REPO)|g'

# Bloque 1: CNI y nodos Ready (k3s ya instalado con scripts/10 y 11)
cluster:
	./scripts/20-calico.sh

# Bloque 4: ArgoCD + repo + Application raíz (dispara el sync inicial)
argocd:
	./scripts/40-argocd.sh

# Esperan a que las Applications de cada bloque estén Healthy (se etiquetan con block=<nombre>)
infra:
	$(KUBECTL_WAIT) -l block=infra --timeout=$(TIMEOUT)
gateway:
	$(KUBECTL_WAIT) -l block=gateway --timeout=$(TIMEOUT)
observability:
	$(KUBECTL_WAIT) -l block=observability --timeout=$(TIMEOUT)
expose:
	$(KUBECTL_WAIT) -l block=expose --timeout=$(TIMEOUT)

status:
	kubectl get nodes -o wide
	kubectl -n argocd get applications
