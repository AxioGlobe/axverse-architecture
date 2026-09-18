# AxioGlobe Codex Runner

This harness makes ChatGPT Desktop Codex the primary local executor while preserving the AxioGlobe 100-agent routing system.

## Start a task

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\codex\start-task.ps1 -Task "Build the Archicad Wall Assembly Builder" -MaxAgents 8
```

This creates a run under `.axioglobe-codex-runs/`, records the Git baseline, and runs the AxioGlobe specialist router. It makes no OpenAI API calls.

## Work in Codex

Codex should read `AGENTS.md`, consult the selected specialist prompts in `tools/ruflo/agents/registry.json`, implement the task locally, run real validation, then perform QA and final review.

## Finish and measure

Example:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\codex\finish-task.ps1 `
  -BuildCommand "cmake --build build --config Release" `
  -TestCommand "ctest --test-dir build --output-on-failure" `
  -TestsTotal 96 -TestsPassed 94 -TestsFailed 2 `
  -AcceptanceTotal 14 -AcceptanceMet 12 `
  -ReviewFindings 17 -ReviewResolved 15
```

Only supply quantitative counts that were actually observed. The harness also measures Git diff statistics and command exit codes automatically.

## API runner

`tools/ruflo/run-squad.ps1` remains available as an optional API-billed backend. Codex should not use it unless the user explicitly requests API execution.
