#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..", "..");
const registry = JSON.parse(fs.readFileSync(path.join(__dirname, "agents", "registry.json"), "utf8"));

function arg(name, fallback = null) {
  const i = process.argv.indexOf(name);
  return i >= 0 && i + 1 < process.argv.length ? process.argv[i + 1] : fallback;
}
function flag(name) { return process.argv.includes(name); }
function safeName(s) { return s.replace(/[^a-zA-Z0-9._-]+/g, "-"); }

const task = arg("--task");
if (!task) {
  console.error('Usage: node tools/ruflo/run-squad.mjs --task "task description" [--max-agents 8] [--concurrency 3] [--no-synthesis]');
  process.exit(1);
}

const apiKey = process.env.OPENAI_API_KEY;
if (!apiKey || apiKey.length < 20) {
  console.error("OPENAI_API_KEY is missing. Configure it in the Windows user environment first.");
  process.exit(1);
}

const maxAgents = Math.max(3, Math.min(Number(arg("--max-agents", "8")), 25));
const concurrency = Math.max(1, Math.min(Number(arg("--concurrency", "3")), 8));
const noSynthesis = flag("--no-synthesis");

const planProc = spawnSync(process.execPath, [
  path.join(__dirname, "route-task.mjs"),
  "--task", task,
  "--max-agents", String(maxAgents),
  "--json"
], { cwd: repoRoot, encoding:"utf8" });

if (planProc.status !== 0) {
  console.error(planProc.stderr || "Failed to generate AxioGlobe routing plan.");
  process.exit(planProc.status || 1);
}
const plan = JSON.parse(planProc.stdout);
const bySlug = new Map(registry.agents.map(a => [a.slug, a]));

const runId = new Date().toISOString().replace(/[:.]/g, "-");
const runDir = path.join(repoRoot, ".axioglobe-runs", runId);
fs.mkdirSync(runDir, { recursive:true });
fs.writeFileSync(path.join(runDir, "plan.json"), JSON.stringify(plan, null, 2));

async function openAIResponse({model, reasoning, instructions, input, maxOutputTokens=3500}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 180000);
  try {
    const response = await fetch("https://api.openai.com/v1/responses", {
      method:"POST",
      headers:{
        "Authorization":"Bearer " + apiKey,
        "Content-Type":"application/json"
      },
      body:JSON.stringify({
        model,
        instructions,
        input,
        reasoning:{ effort:reasoning },
        max_output_tokens:maxOutputTokens,
        store:false
      }),
      signal:controller.signal
    });

    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      const message = body && body.error && body.error.message ? body.error.message : "OpenAI HTTP " + response.status;
      throw new Error(message);
    }

    const text = (body.output || [])
      .flatMap(item => item.content || [])
      .filter(c => c.type === "output_text")
      .map(c => c.text)
      .join("\n")
      .trim();

    return {
      id:body.id,
      model:body.model || model,
      text:text || "[No text output returned]",
      usage:body.usage || null
    };
  } finally {
    clearTimeout(timer);
  }
}

async function runAgent(member) {
  const definition = bySlug.get(member.slug);
  if (!definition) throw new Error("Missing registry definition: " + member.slug);

  const instructions = [
    definition.systemPrompt,
    "",
    "Output contract:",
    ...definition.outputContract.map((x,i) => (i+1) + ". " + x),
    "",
    "You are one specialist inside a coordinated AxioGlobe squad. Do not assume other agents results. Focus on your specialty."
  ].join("\n");

  const input = [
    "AxioGlobe task: " + task,
    "Task complexity score: " + plan.complexity,
    "Risk classification: " + (plan.highRisk ? "high" : "normal"),
    "Matched domains: " + (plan.matchedCategories.join(", ") || "general"),
    "",
    "Provide your specialist contribution for the coordinator."
  ].join("\n");

  const started = Date.now();
  try {
    const result = await openAIResponse({
      model:member.model,
      reasoning:member.reasoning,
      instructions,
      input
    });
    const record = {
      agent:member.slug,
      role:member.role,
      category:member.category,
      model:result.model,
      requestedModel:member.model,
      reasoning:member.reasoning,
      durationMs:Date.now()-started,
      usage:result.usage,
      success:true,
      output:result.text
    };
    fs.writeFileSync(path.join(runDir, safeName(member.slug)+".json"), JSON.stringify(record,null,2));
    fs.writeFileSync(path.join(runDir, safeName(member.slug)+".md"), "# " + member.role + "\n\n" + result.text + "\n");
    return record;
  } catch (error) {
    const record = {
      agent:member.slug,
      role:member.role,
      category:member.category,
      requestedModel:member.model,
      reasoning:member.reasoning,
      durationMs:Date.now()-started,
      success:false,
      error:error instanceof Error ? error.message : String(error)
    };
    fs.writeFileSync(path.join(runDir, safeName(member.slug)+".json"), JSON.stringify(record,null,2));
    return record;
  }
}

async function mapLimit(items, limit, fn) {
  const results = new Array(items.length);
  let next = 0;
  async function worker() {
    while (true) {
      const i = next++;
      if (i >= items.length) return;
      results[i] = await fn(items[i], i);
      const status = results[i].success ? "OK" : "FAIL";
      console.log("[" + status + "] " + items[i].slug + " -> " + items[i].model);
    }
  }
  await Promise.all(Array.from({length:Math.min(limit, items.length)}, worker));
  return results;
}

console.log("\nAxioGlobe AI Squad Execution");
console.log("=============================");
console.log("Task:", task);
console.log("Complexity:", plan.complexity, "| base:", plan.baseModel, "| reasoning:", plan.reasoning);
console.log("Squad:", plan.squadSize, "of", registry.totalAgents, "registered agents");
console.log("Run:", runId, "\n");

const results = await mapLimit(plan.squad, concurrency, runAgent);
const successful = results.filter(r => r.success);
const failed = results.filter(r => !r.success);

let synthesis = null;
if (!noSynthesis && successful.length > 0) {
  const synthesisModel = plan.complexity >= 0.68 || plan.highRisk ? "gpt-5.6-sol" : "gpt-5.6-terra";
  const synthesisReasoning = plan.complexity >= 0.68 ? "high" : "medium";
  const combined = successful.map(r => "## " + r.role + " (" + r.agent + ")\n" + r.output).join("\n\n");
  const instructions = [
    "You are the AxioGlobe Chief Coordinator.",
    "Synthesize specialist outputs into one engineering decision and implementation plan.",
    "Resolve disagreements explicitly. Do not claim code/tests were executed unless an agent provided evidence.",
    "Return: Decision, Work plan, Ownership, Acceptance criteria, Risks, Validation, Deferred questions."
  ].join(" ");

  const synth = await openAIResponse({
    model:synthesisModel,
    reasoning:synthesisReasoning,
    instructions,
    input:"Task: " + task + "\n\nSpecialist outputs:\n" + combined,
    maxOutputTokens:5000
  });
  synthesis = {
    model:synth.model,
    reasoning:synthesisReasoning,
    usage:synth.usage,
    output:synth.text
  };
  fs.writeFileSync(path.join(runDir, "coordinator-summary.md"), "# Coordinator Summary\n\n" + synth.text + "\n");
  fs.writeFileSync(path.join(runDir, "coordinator-summary.json"), JSON.stringify(synthesis,null,2));
}

const manifest = {
  runId,
  task,
  plan,
  successfulAgents:successful.length,
  failedAgents:failed.length,
  results:results.map(r => ({
    agent:r.agent,
    role:r.role,
    requestedModel:r.requestedModel,
    model:r.model,
    reasoning:r.reasoning,
    success:r.success,
    usage:r.usage || null,
    error:r.error || null
  })),
  synthesis:synthesis ? {model:synthesis.model,reasoning:synthesis.reasoning,usage:synthesis.usage} : null
};
fs.writeFileSync(path.join(runDir, "manifest.json"), JSON.stringify(manifest,null,2));

console.log("\nCompleted.");
console.log("Successful agents:", successful.length);
console.log("Failed agents:", failed.length);
console.log("Artifacts:", runDir);
if (synthesis) console.log("Coordinator synthesis: coordinator-summary.md");
