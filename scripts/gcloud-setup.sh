#!/bin/bash
# Corre en /etc/cont-init.d/ como ROOT
# Descarga gcloud SDK + crea symlink para Hermes

GCLOUD_DIR="/opt/data/gcloud-sdk"

if [ ! -f "$GCLOUD_DIR/bin/gcloud" ]; then
    echo "[gcloud-setup] Descargando gcloud SDK..."
    ARCH=$(uname -m)
    case "$ARCH" in
        aarch64|arm64) GCLOUD_ARCH="arm" ;;
        *)             GCLOUD_ARCH="x86_64" ;;
    esac
    mkdir -p "$GCLOUD_DIR"
    curl -sSL --max-time 120 "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-${GCLOUD_ARCH}.tar.gz" \
        | tar xz -C "$GCLOUD_DIR" --strip-components=1 && {
        "$GCLOUD_DIR/bin/gcloud" config set disable_usage_reporting true &>/dev/null || true
        "$GCLOUD_DIR/bin/gcloud" config set component_manager/disable_update_check true &>/dev/null || true
        echo "[gcloud-setup] gcloud SDK listo"
    } || {
        echo "[gcloud-setup] ⚠️  No se pudo descargar gcloud SDK"
        rm -rf "$GCLOUD_DIR"
    }
fi

# Symlink en /usr/local/bin/ (está en el PATH del agente Hermes)
if [ -f "$GCLOUD_DIR/bin/gcloud" ] && [ ! -L /usr/local/bin/gcloud ]; then
    ln -sf "$GCLOUD_DIR/bin/gcloud" /usr/local/bin/gcloud
    echo "[gcloud-setup] Symlink creado en /usr/local/bin/gcloud"
fi
