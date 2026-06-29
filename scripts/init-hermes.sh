#!/bin/bash
set -e

HERMES_HOME="/opt/data"
CONFIG_FILE="${HERMES_HOME}/config.yaml"
ENV_FILE="${HERMES_HOME}/.env"
SANDBOX_DIR="${HERMES_HOME}/sandbox"

echo "[init-hermes] Inicializando volúmenes del sandbox..."
mkdir -p "$SANDBOX_DIR/gcloud-config" \
        "$SANDBOX_DIR/ssh" \
        "$SANDBOX_DIR/gitconfig" \
        "$SANDBOX_DIR/projects"
echo "[init-hermes] Directorios creados en $SANDBOX_DIR"

# ──────────────────────────────────────────────
# 1. config.yaml — Hermes terminal backend
# ──────────────────────────────────────────────
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'YAMLEOF'
terminal:
  backend: docker
  docker_image: "hermes-gcloud:latest"
  docker_volumes:
    - "/opt/data/sandbox/gcloud-config:/root/.config/gcloud"
    - "/opt/data/sandbox/ssh:/root/.ssh"
    - "/opt/data/sandbox/gitconfig:/root/.gitconfig"
    - "/opt/data/sandbox/projects:/workspace/projects"
  docker_persist_across_processes: true
  container_persistent: true
  timeout: 180
YAMLEOF
    echo "[init-hermes] config.yaml creado"
elif ! grep -q "docker_volumes" "$CONFIG_FILE" 2>/dev/null; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%s)"
    cat >> "$CONFIG_FILE" << 'YAMLEOF'

terminal:
  backend: docker
  docker_image: "hermes-gcloud:latest"
  docker_volumes:
    - "/opt/data/sandbox/gcloud-config:/root/.config/gcloud"
    - "/opt/data/sandbox/ssh:/root/.ssh"
    - "/opt/data/sandbox/gitconfig:/root/.gitconfig"
    - "/opt/data/sandbox/projects:/workspace/projects"
  docker_persist_across_processes: true
  container_persistent: true
  timeout: 180
YAMLEOF
    echo "[init-hermes] config.yaml actualizado con docker_volumes"
else
    echo "[init-hermes] config.yaml ya configurado"
fi

# ──────────────────────────────────────────────
# 2. .env — API keys desde variables de entorno
# ──────────────────────────────────────────────
# Si no existe /opt/data/.env, lo creamos a partir
# de las variables que docker-compose inyectó desde .env
if [ ! -f "$ENV_FILE" ]; then
    : > "$ENV_FILE"
    echo "# Auto-generado por init-hermes.sh" >> "$ENV_FILE"

    for var in ANTHROPIC_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY \
               TOGETHER_API_KEY TELEGRAM_BOT_TOKEN DISCORD_BOT_TOKEN; do
        if [ -n "${!var}" ]; then
            echo "${var}=${!var}" >> "$ENV_FILE"
            echo "[init-hermes]   → $var escrita en .env"
        fi
    done

    if [ ! -s "$ENV_FILE" ]; then
        rm -f "$ENV_FILE"
        echo "[init-hermes] ⚠️  Ninguna API key encontrada en variables de entorno."
        echo "[init-hermes]    Define al menos una (ANTHROPIC_API_KEY, OPENAI_API_KEY, OPENROUTER_API_KEY) en tu .env del host."
    else
        echo "[init-hermes] .env creado desde variables de entorno"
    fi
fi

# ──────────────────────────────────────────────
# 3. Git config persistente
# ──────────────────────────────────────────────
GITCONF_FILE="$SANDBOX_DIR/gitconfig/.gitconfig"
if [ ! -f "$GITCONF_FILE" ] && { [ -n "$GIT_USER_NAME" ] || [ -n "$GIT_USER_EMAIL" ]; }; then
    {
        echo "[user]"
        [ -n "$GIT_USER_NAME" ]  && echo "	name = $GIT_USER_NAME"
        [ -n "$GIT_USER_EMAIL" ] && echo "	email = $GIT_USER_EMAIL"
        echo "[core]"
        echo "	autocrlf = input"
        echo "	safecrlf = warn"
        echo "[init]"
        echo "	defaultBranch = main"
    } > "$GITCONF_FILE"
    echo "[init-hermes] .gitconfig creado en sandbox"
fi

# ──────────────────────────────────────────────
# 4. SSH keys
# ──────────────────────────────────────────────
if [ -n "$SSH_PRIVATE_KEY" ] && [ ! -f "$SANDBOX_DIR/ssh/id_ed25519" ]; then
    echo "$SSH_PRIVATE_KEY" > "$SANDBOX_DIR/ssh/id_ed25519"
    chmod 600 "$SANDBOX_DIR/ssh/id_ed25519"

    if [ -n "$SSH_PUBLIC_KEY" ]; then
        echo "$SSH_PUBLIC_KEY" > "$SANDBOX_DIR/ssh/id_ed25519.pub"
        chmod 644 "$SANDBOX_DIR/ssh/id_ed25519.pub"
    fi
    echo "[init-hermes] SSH private key instalada en sandbox"
elif [ ! -f "$SANDBOX_DIR/ssh/id_ed25519" ]; then
    # Sin clave provista — generamos una (sirve para GitHub sin auth)
    ssh-keygen -t ed25519 -f "$SANDBOX_DIR/ssh/id_ed25519" -N "" -C "hermes-sandbox" 2>/dev/null || true
    if [ -f "$SANDBOX_DIR/ssh/id_ed25519" ]; then
        echo "[init-hermes] SSH key generada automáticamente para sandbox"
    fi
fi

# ──────────────────────────────────────────────
# 5. GCP service account key
# ──────────────────────────────────────────────
if [ -n "$GCLOUD_SERVICE_ACCOUNT_KEY" ] && [ ! -f "$SANDBOX_DIR/gcloud-config/key.json" ]; then
    echo "$GCLOUD_SERVICE_ACCOUNT_KEY" > "$SANDBOX_DIR/gcloud-config/key.json"
    chmod 600 "$SANDBOX_DIR/gcloud-config/key.json"
    echo "[init-hermes] GCP service account key almacenada para el sandbox"
elif [ -f "$SANDBOX_DIR/gcloud-config/key.json" ]; then
    echo "[init-hermes] GCP key.json ya presente en sandbox"
fi

# ──────────────────────────────────────────────
# Resumen
# ──────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  init-hermes completado                                 ║"
echo "║"
echo "║  📁 Sandbox:  $SANDBOX_DIR"
echo "║  🔑 .env:     $([ -f "$ENV_FILE" ] && echo '✓ creado' || echo '✗ pendiente (edita .env del host y reinicia)')"
echo "║  🔐 SSH:      $([ -f "$SANDBOX_DIR/ssh/id_ed25519" ] && echo '✓ instalada' || echo '✗ pendiente')"
echo "║  🐙 Git:      $([ -f "$GITCONF_FILE" ] && echo '✓ configurado' || echo '· opcional (usa GIT_USER_NAME/EMAIL)')"
echo "║  ☁️  GCP:      $([ -f "$SANDBOX_DIR/gcloud-config/key.json" ] && echo '✓ service account' || echo '· opcional (usa GCLOUD_SERVICE_ACCOUNT_KEY o gcloud auth login manual)')"
echo "║"
echo "║  Para hacer gcloud auth login MANUAL (sin service account):"
echo "║    docker exec -it hermes compose up    (primero up)"
echo "║    docker exec -it hermes bash"
echo "║    gcloud auth login"
echo "║    exit"
echo "║    docker compose restart"
echo "╚══════════════════════════════════════════════════════════════╝"

exec /opt/hermes/.venv/bin/hermes gateway run
