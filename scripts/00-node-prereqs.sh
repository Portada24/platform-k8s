#!/usr/bin/env bash
# Ejecutar en CADA nodo (Ubuntu 24.04). Prepara el SO para k3s y Longhorn.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y open-iscsi nfs-common cryptsetup curl jq

# Longhorn: iSCSI y módulos de kernel
sudo systemctl enable --now iscsid
printf 'iscsi_tcp\ndm_crypt\n' | sudo tee /etc/modules-load.d/longhorn.conf >/dev/null
sudo modprobe iscsi_tcp || true
sudo modprobe dm_crypt || true

# multipathd interfiere con los dispositivos de Longhorn
sudo systemctl disable --now multipathd.service multipathd.socket 2>/dev/null || true

echo "OK: nodo preparado ($(hostname))"
