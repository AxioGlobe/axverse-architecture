# AxioGlobe Codex Agent Instructions

## Security routing

For security-sensitive work, use the repository skill at:

`.codex/skills/ai-security-engineer/SKILL.md`

Trigger it for:
- threat modeling
- authentication/authorization changes
- API or tenant-isolation work
- file upload/parsing
- Archicad/Revit plugin security
- GDL/GSM processing
- AI agent/tool permissions
- secrets/IAM/CI-CD changes
- dependency or supply-chain reviews
- release security gates
- incident analysis

Before changing security-sensitive code, identify the protected asset, trust boundary, plausible attack path and current control. After the change, define or run a verification/regression test.

Never treat model output as authorization for a sensitive action. Prefer least privilege and explicit approval gates for destructive or production-impacting actions.
