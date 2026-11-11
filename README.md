# Plataforma Kubernetes cloud-native (prueba Cloud Senior)

Estado del repositorio: **parte 1** (bloque 1 Cluster, bootstrap de ArgoCD y MetalLB). Pendiente: cert-manager,
Gateway API + Istio, Longhorn, CloudNativePG, registry, app ToDo, observabilidad y exposición pública.

## Prerrequisitos
- 2 o 3 VMs Ubuntu 24.04 (1 control-plane + 1-2 workers). No se usa kind/minikube/k3d.
- En tu máquina: `kubectl`, `helm`, `git`, `make`.
- Repo Git privado y un PAT de solo lectura para ArgoCD.

## Decisión: k3s (y no kubeadm)
| Criterio | k3s | kubeadm |
|---|---|---|
| Recursos de las VMs | Bajo consumo, un solo binario | Más memoria y más componentes a operar |
| Tiempo de instalación | Minutos, declarativo con `config.yaml` | Largo: runtime, kubeadm, kubelet, init/join |
| Fidelidad a producción | Distribución certificada CNCF; con **etcd embebido** (`cluster-init`) en vez de SQLite | Mayor fidelidad y control |
| Qué se pierde | Algunos componentes vienen empaquetados (se desactivan traefik y servicelb) | Nada, pero hay que instalar CNI, LB y storage a mano |

Se elige k3s porque la prueba dura 5 días y el valor está en la plataforma (GitOps, Gateway API, observabilidad),
no en el bootstrap. Con etcd embebido y Calico se mantienen prácticas de producción. Trade-off a explicar en el review:
un solo control-plane no es HA; para HA real se agregarían 2 servidores más con `--server`.

**CNI: Calico** (flannel desactivado). Da NetworkPolicy completo, necesario para segmentar frontend → API → PostgreSQL.
**MetalLB L2** entrega la IP externa al Gateway de Istio; se gestiona por GitOps.

## Instalación desde cero (bloque 1 y 4)
1. En cada nodo: `./scripts/00-node-prereqs.sh` (instala open-iscsi para Longhorn).
2. Control-plane: editar `tls-san` en `bootstrap/k3s/server-config.yaml` y ejecutar `./scripts/10-k3s-server.sh`.
3. Workers: `K3S_URL=https://<ip>:6443 K3S_TOKEN=<token> ./scripts/11-k3s-agent.sh`.
4. Copiar el kubeconfig a tu máquina y ejecutar `make cluster` (Calico + nodos Ready).
5. Ajustar el rango de IPs en `manifests/metallb-config/pool.yaml` (misma red L2, fuera del DHCP).
6. `make set-repo REPO=https://github.com/<usuario>/platform-k8s.git`, commit y push.
7. `GIT_REPO_URL=<url> GIT_TOKEN=<pat> make argocd` (instala ArgoCD, registra el repo privado y aplica la Application raíz).
8. `make infra` espera a que las Applications de infraestructura queden Healthy.

El token del repo se crea como Secret en runtime; nunca se versiona.

## App of Apps y sync waves
`bootstrap/root-app.yaml` tiene tres sources (`infra/`, `observability/`, `apps/`), cada uno con Applications hijas.
Orden por sync wave (se irá completando): MetalLB (-10) → config de MetalLB (-9) → CRDs de Gateway API y cert-manager →
Istio → Longhorn → CloudNativePG → aplicación. ArgoCD incluye un health check personalizado para `Application`, necesario
para que las waves esperen a que cada hija esté Healthy.

## Hostnames para /etc/hosts (IP del Gateway asignada por MetalLB)
`argocd.local grafana.local kiali.local jaeger.local longhorn.local todo.local`

## Por verificar antes del review
- Versiones de Calico (`versions.env`) y del chart de MetalLB (`infra/metallb.yaml`): confirmarlas contra sus releases.
- Istio: 1.29 ya no tiene soporte comunitario; usar 1.30.x o 1.31.x, y revisar compatibilidad con Gateway API v1.4.
- Calico en k3s: si los nodos no pasan a Ready, revisar `kubectl -n calico-system get pods` y las rutas CNI de k3s.
