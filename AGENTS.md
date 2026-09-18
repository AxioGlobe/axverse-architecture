# AxioGlobe Codex Instructions

## Purpose

This repository uses ChatGPT Desktop Codex as the primary local development executor.

The AxioGlobe 100-agent registry remains the source of specialist roles, but those roles are **not** 100 simultaneous API calls. Codex should use the registry and router to decide which specialist perspectives are needed for a task, then execute the work locally against the repository.

## Canonical files

- Agent registry: `tools/ruflo/agents/registry.json`
- Dynamic router: `tools/ruflo/route-task.mjs`
- Routing policy: `tools/ruflo/model-routing.json`
- Ruflo coordination: `tools/ruflo/`
- Codex run harness: `tools/codex/`

The OpenAI API runner at `tools/ruflo/run-squad.ps1` is optional and must **not** be used unless the user explicitly asks to use API billing.

## Mandatory workflow for substantial tasks

For feature work, refactors, debugging, architecture, performance, security-sensitive work, or changes spanning multiple files:

1. **Preflight**
   - Confirm repository root, branch, working-tree state, available toolchain, and relevant build/test commands.
   - Read applicable `AGENTS.md` files before editing.
   - Do not overwrite unrelated local changes.

2. **Start quantitative run**
   - Run:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\tools\codex\start-task.ps1 -Task "<task>" -MaxAgents 8
     ```
   - This records the baseline commit and runs the AxioGlobe router without making OpenAI API calls.

3. **Use the selected specialist roles**
   - Read the selected agents from the generated run plan.
   - For each selected role, consult its `systemPrompt`, `outputContract`, risk profile, and tags in `tools/ruflo/agents/registry.json`.
   - Treat the roles as structured specialist review passes inside the Codex task.
   - The chief coordinator owns decomposition and final synthesis.
   - QA and final-review roles must be honored before declaring success.

4. **Plan**
   - Identify files/components affected.
   - State acceptance criteria.
   - Identify build/test/validation commands.
   - Prefer minimal, reversible changes.

5. **Implement**
   - Make repository changes directly.
   - Do not fabricate completed work.
   - Do not claim a build/test passed unless the command was actually run and succeeded.

6. **Verify**
   - Run the relevant build, lint, unit, integration, regression, and/or platform checks available for the changed area.
   - If a required tool is unavailable, record that limitation explicitly.

7. **Review**
   - Perform the selected QA specialist pass.
   - Perform the selected final cross-domain reviewer pass.
   - Resolve material findings or record them as outstanding.

8. **Finish quantitative run**
   - Run `tools/codex/finish-task.ps1` with actual build/test and acceptance numbers when available.
   - Never invent test totals, pass rates, findings, timings, or build results.
   - The metrics harness must reflect real Git state and real command outcomes.

9. **Final report**
   - Summarize:
     - task and complexity
     - selected specialists
     - files changed
     - lines added/removed
     - build result
     - tests total/passed/failed and pass rate when known
     - QA/review findings
     - acceptance criteria met/outstanding
     - elapsed time
     - remaining risks

## Model policy

When Codex offers model/reasoning controls, use the AxioGlobe router as guidance:
- Luna-equivalent routing: simple, low-risk, repetitive work.
- Terra-equivalent routing: normal engineering work.
- Sol-equivalent routing: complex architecture, difficult debugging, security-sensitive, cross-domain, or high-risk work.

Do not attempt to call ChatGPT subscription usage through the OpenAI API. Subscription-backed Codex execution and API billing are separate.

## Safety and secrets

- Never print, commit, echo, or log API keys or other secrets.
- Never commit local run artifacts from `.axioglobe-codex-runs/`.
- Ask before destructive repository operations, dependency removals, history rewrites, or deleting user work.
- Do not disable security checks merely to make a build pass.

## Small tasks

For trivial documentation, typo, or formatting changes, the full multi-role workflow may be shortened, but still run appropriate validation and do not invent results.
