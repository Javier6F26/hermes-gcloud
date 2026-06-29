# Hermes + gcloud — Setup Multi-usuario

## Primera instalación (único paso)

```bash
cp .env.template .env
nano .env          # descomenta al menos una API key
docker compose up -d
```

El script `init-hermes.sh` configura automáticamente:
- `.env` con tus API keys
- `config.yaml` con volúmenes persistentes
- SSH keys (genera una automáticamente si no se provee una)
- Git config (si pusiste `GIT_USER_NAME` / `GIT_USER_EMAIL` en `.env`)
- GCP service account (si pusiste `GCLOUD_SERVICE_ACCOUNT_KEY` en `.env`)

## Variables disponibles en `.env`

| Variable | Obligatorio | Descripción |
|---|---|---|
| `ANTHROPIC_API_KEY` | ✅ Sí¹ | LLM provider |
| `OPENAI_API_KEY` | ❌ | Alternativa |
| `GIT_USER_NAME` / `GIT_USER_EMAIL` | ❌ | Identity para commits del sandbox |
| `SSH_PRIVATE_KEY` | ❌ | Deploy key para repos privados |
| `GCLOUD_SERVICE_ACCOUNT_KEY` | ❌ | Service account JSON (todo en una línea) |

> ¹ Se necesita al menos una API key (Anthropic, OpenAI, u OpenRouter).

## gcloud auth manual (sin service account)

```bash
docker exec -it hermes bash
gcloud auth login
exit
docker compose restart
```

## SSH manual (sin variable de entorno)

```bash
docker cp ~/.ssh/id_ed25519* hermes_gcloud-sandbox_1:/root/.ssh/
```

## Persistencia

Los volúmenes Docker (`hermes_data`, `hermes_output`) persisten entre `down && up`.
