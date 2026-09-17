# AxioGlobe Ruflo Development Harness

Ruflo is used by AxioGlobe as a **development-only multi-agent orchestration harness**. It is not a runtime dependency of Axverse, the Archicad plugin, Revit tooling, PEER, AutoBid, or production BIM services.

## Pinned version

`ruflo@3.42.0`

Ruflo currently requires Node.js 20 or newer.

## Windows install

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\ruflo\install.ps1"
```

The installer initializes Ruflo with the **full preset**, including project-local agent definitions, MCP configuration, hooks, memory/orchestration configuration, and Claude/Ruflo project instructions. It then runs `ruflo doctor --fix` and plugin discovery.

## Architecture rule

Ruflo may coordinate development tasks such as:

- C++ Archicad implementation
- C# Revit implementation
- GDL generation/validation engineering
- test generation and QA
- security review
- documentation
- architecture review
- repository analysis and refactoring

Ruflo must not be introduced as a production dependency of AxioGlobe customer-facing software. Production services and plugins must remain independently deployable and testable without Ruflo.

## Recommended AxioGlobe swarm

Use hierarchical coordination for substantial engineering work. A typical software task can use:

- planner / system architect
- C++ or C# implementation agents
- BIM-domain reviewer
- test/QA agent
- security reviewer
- documentation agent
- final verifier

Do not spawn large swarms for trivial one-file changes. Scale the swarm to the task.

## Useful commands

```bash
npx ruflo@3.42.0 doctor
npx ruflo@3.42.0 agent list
npx ruflo@3.42.0 swarm init --topology hierarchical
npx ruflo@3.42.0 mcp list
npx ruflo@3.42.0 discover-plugins
```

## Updating Ruflo

Do not switch this repository to `ruflo@latest` automatically. Update the pinned version deliberately on an integration branch, run the Ruflo bootstrap/doctor checks, inspect generated configuration changes, and merge only after review.
