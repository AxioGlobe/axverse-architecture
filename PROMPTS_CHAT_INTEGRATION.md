# Prompts.chat integration

Prompts.chat is pinned into this branch as a Git submodule at `integrations/prompts-chat`.

Pinned upstream commit:

`f78a1c5136fa080155d928e0d7e2b4a41ddef03e`

## Purpose for AxioGlobe

Use Prompts.chat as the foundation for an internal prompt registry rather than exposing a generic public prompt list directly inside Axverse.

Recommended AxioGlobe namespaces:

- `AX-DESIGN-*`
- `AX-TECH-*`
- `AX-DOC-*`
- `AX-GDL-*`
- `AX-REVIT-*`
- `AX-MANUFACTURER-*`
- `AX-CONTRACTOR-*`
- `AX-PEER-*`
- `AX-AUTOBID-*`
- `AX-VERIFY-*`

## Local checkout

```bash
git checkout integration/prompts-chat
git submodule update --init --recursive
cd integrations/prompts-chat
npm ci
```

Prompts.chat currently requires Node.js 24.x and PostgreSQL for a full self-hosted runtime.

Production secrets, database credentials, model API keys, and authentication secrets must not be committed to this repository.
