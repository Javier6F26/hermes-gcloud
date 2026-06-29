#!/bin/bash
set -e

GCLOUD_DIR="/opt/data/gcloud-sdk"

if [ ! -f "$GCLOUD_DIR/bin/gcloud" ]; then
    echo "[init-hermes] Descargando gcloud SDK..."
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
        echo "[init-hermes] gcloud SDK listo"
    } || {
        echo "[init-hermes] ⚠️  No se pudo descargar gcloud SDK"
        rm -rf "$GCLOUD_DIR"
    }
fi

export PATH="$GCLOUD_DIR/bin:$PATH"
exec /opt/hermes/.venv/bin/hermes gateway run
