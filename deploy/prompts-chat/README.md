# AxioGlobe Prompt Registry

This folder runs the AxioGlobe-branded Prompts.chat instance with PostgreSQL using Docker Compose.

## Windows quick start

Requirements:
- Docker Desktop
- Git

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy\prompts-chat\start.ps1
```

The launcher will:
1. Generate secure local secrets in `deploy/prompts-chat/.env` if they do not exist.
2. Pull the official `ghcr.io/f/prompts.chat:latest` image.
3. Start PostgreSQL and the prompt registry.
4. Apply Prompts.chat database migrations automatically through the official container entrypoint.
5. Open the registry in your browser.

Local URL:

```text
http://localhost:4444
```

The local runtime uses credentials authentication and allows registration so the first local account can be created. The `.env` file is ignored by Git and must never be committed.

## Manual start

```powershell
cd deploy\prompts-chat
copy .env.example .env
# Edit .env and replace the placeholder secrets.
docker compose --env-file .env up -d
```

## Stop

```powershell
docker compose --env-file .\deploy\prompts-chat\.env -f .\deploy\prompts-chat\compose.yml down
```

The PostgreSQL Docker volume is persistent, so prompts and accounts survive container restarts.

## AxioGlobe defaults

- Name: AxioGlobe Prompt Registry
- Private prompts: enabled
- Prompt versioning/change requests: enabled
- Categories and tags: enabled
- Comments: enabled
- MCP: enabled
- AI search: disabled until an AI API key is deliberately configured
- AI generation: disabled until an AI API key is deliberately configured

## Production

For production, use a managed PostgreSQL database and a managed web deployment. Set at minimum:

- `DATABASE_URL`
- `DIRECT_URL`
- `AUTH_SECRET`
- `PCHAT_NAME=AxioGlobe Prompt Registry`
- `PCHAT_FEATURE_MCP=true`
- production authentication provider credentials

Do not use the local PostgreSQL password or local `AUTH_SECRET` in production.
