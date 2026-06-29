#!/bin/bash
# Este script corre en /etc/cont-init.d/ como ROOT
# Crea el symlink de gcloud en /usr/local/bin/ para que Hermes lo vea

GCLOUD_DIR="/opt/data/gcloud-sdk"

if [ -f "$GCLOUD_DIR/bin/gcloud" ] && [ ! -L /usr/local/bin/gcloud ]; then
    ln -sf "$GCLOUD_DIR/bin/gcloud" /usr/local/bin/gcloud
    echo "[gcloud-setup] Symlink creado en /usr/local/bin/gcloud"
fi
