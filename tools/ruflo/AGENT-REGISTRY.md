# AxioGlobe 100-Agent Development Organization

This directory defines **100 permanent specialist roles** for AxioGlobe development.

The design intentionally does **not** keep 100 agents running at once. A task is routed to a temporary squad chosen from the registry, and the model is selected per task/role.

## Model tiers

- `gpt-5.6-luna` — simple, high-volume, low-risk work
- `gpt-5.6-terra` — standard engineering work
- `gpt-5.6-sol` — complex architecture, difficult debugging, security-sensitive or high-risk work

The router also selects reasoning effort from `none` through `max` based on task complexity.

## Registry

`agents/registry.json` contains exactly 100 roles across:

| Area | Agents |
|---|---:|
| Coordination & architecture | 8 |
| Archicad / C++ / BIM | 16 |
| Revit / C# / engineering | 14 |
| GDL Engine | 12 |
| Backend / API / database | 10 |
| AI / data / retrieval | 10 |
| QA / security / performance | 14 |
| DevOps / product / docs / release | 16 |
| **Total** | **100** |

## Plan a task

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ruflo\invoke-squad.ps1 -Task "Build the Archicad Wall Assembly Builder"
```

Limit the squad:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ruflo\invoke-squad.ps1 -Task "Fix a README typo" -MaxAgents 4
```

Spawn the selected Ruflo roles:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ruflo\invoke-squad.ps1 -Task "Implement Product DNA Browser API integration" -Spawn
```

## Important execution rule

The **role registry** and **model router** are AxioGlobe-owned. Ruflo remains the coordination/memory/swarm layer. This avoids coupling AxioGlobe's model policy to Ruflo's Claude-oriented tier assumptions.

## Escalation

The policy escalates Luna → Terra → Sol for high-risk work, cross-domain complexity, low confidence, failed tests or repeated failures. The task runner should record outcomes so routing thresholds can later be tuned from real AxioGlobe data.


## Execute a routed OpenAI squad

Planning and execution are separate on purpose.

Preview the squad/model choices without making API calls:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ruflo\invoke-squad.ps1 -Task "Build the Archicad Wall Assembly Builder"
```

Execute the routed specialists through the OpenAI Responses API and produce a coordinator synthesis:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\ruflo\run-squad.ps1 -Task "Build the Archicad Wall Assembly Builder" -MaxAgents 8 -Concurrency 3
```

Execution artifacts are written to `.axioglobe-runs/<run-id>/` and ignored by Git. Each run records the routing plan, per-agent model/reasoning choice, token usage returned by the API, success/failure state, specialist outputs, and coordinator synthesis.

## Responsibility split

- **Ruflo:** swarm lifecycle, role coordination, memory, hooks, development orchestration.
- **AxioGlobe Agent Registry:** the 100 permanent specialist role definitions and prompts.
- **AxioGlobe Model Router:** complexity/risk analysis, squad selection, Luna/Terra/Sol selection, reasoning effort, escalation policy.
- **OpenAI Responses API:** model execution for the selected specialists.

This separation keeps AxioGlobe's model policy independent from Ruflo's native Claude-oriented routing tiers.
