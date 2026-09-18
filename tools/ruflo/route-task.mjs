#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const registryPath = path.join(__dirname, "agents", "registry.json");
const routingPath = path.join(__dirname, "model-routing.json");
const registry = JSON.parse(fs.readFileSync(registryPath, "utf8"));
const routing = JSON.parse(fs.readFileSync(routingPath, "utf8"));

function arg(name, fallback = null) {
  const i = process.argv.indexOf(name);
  return i >= 0 && i + 1 < process.argv.length ? process.argv[i + 1] : fallback;
}
function flag(name) { return process.argv.includes(name); }

const task = arg("--task");
if (!task) {
  console.error('Usage: node tools/ruflo/route-task.mjs --task "task description" [--max-agents 8] [--spawn] [--json]');
  process.exit(1);
}

const maxAgents = Math.max(3, Math.min(Number(arg("--max-agents", registry.activationPolicy.defaultMaxSquad)), registry.activationPolicy.hardMaxSquad));
const lower = task.toLowerCase();
const words = lower.split(/\s+/).filter(Boolean);

const has = (kw) => lower.includes(kw);
const hitCount = (list) => list.reduce((n, k) => n + (has(k) ? 1 : 0), 0);

let complexity = 0.18;
complexity += Math.min(hitCount(routing.scoring.highKeywords) * 0.075, 0.45);
complexity += Math.min(hitCount(routing.scoring.mediumKeywords) * 0.035, 0.20);
complexity -= Math.min(hitCount(routing.scoring.lowKeywords) * 0.04, 0.12);

const implementationIntent = hitCount(routing.scoring.implementationIntents || []) > 0;
const platformFeature = hitCount(routing.scoring.platformKeywords || []) > 0;
if (implementationIntent) complexity += routing.scoring.featureBuildBonus || 0;
if (implementationIntent && platformFeature) complexity += routing.scoring.platformFeatureBonus || 0;

if (words.length > 80) complexity += routing.scoring.longTaskBonus;
const highRisk = hitCount(routing.scoring.highRiskKeywords) > 0;
if (highRisk) complexity += routing.scoring.highRiskBonus;

const categorySignals = {
  "coordination-architecture":["architecture","system","integration","plan","requirements","roadmap"],
  "archicad-cpp-bim":["archicad","cpp","bim","graphisoft","ifc","palette"],
  "revit-csharp-engineering":["revit","csharp","autodesk","mep","structural"],
  "gdl-engine":["gdl","object","parameter","material","geometry"],
  "backend-api-database":["backend","api","postgres","database","auth","websocket","queue"],
  "ai-data-retrieval":["ai","model","prompt","rag","embedding","document","agent","retrieval"],
  "qa-security-performance":["test","qa","security","performance","load","privacy","reliability"],
  "devops-product-docs-release":["devops","github","ci","release","cloud","windows","documentation","onboarding"]
};

const matchedCategories = Object.entries(categorySignals)
  .filter(([, terms]) => terms.some(has))
  .map(([cat]) => cat);
if (matchedCategories.length >= 2) complexity += routing.scoring.crossDomainBonus;

complexity = Math.max(0, Math.min(1, Number(complexity.toFixed(3))));

function tierFor(score) {
  if (score <= routing.thresholds.lunaMax && !highRisk) return "luna";
  if (score <= routing.thresholds.terraMax && !highRisk) return "terra";
  return "sol";
}
const tierOrder = { luna:0, terra:1, sol:2 };
function maxTier(a,b) { return tierOrder[a] >= tierOrder[b] ? a : b; }

function reasoningFor(score) {
  return routing.reasoningByComplexity.find(x => score <= x.max)?.effort ?? "high";
}

const featureSignals = [
  {
    terms:["wall assembly","wall builder","wall assembly builder"],
    boosts:{
      "axioglobe-archicad-elements":14,
      "axioglobe-archicad-properties":12,
      "axioglobe-bim-data-model":10,
      "axioglobe-bim-workflow":9,
      "axioglobe-archicad-classification":8,
      "axioglobe-product-normalization":7
    },
    penalties:{
      "axioglobe-archicad-palette-ui":-5,
      "axioglobe-archicad-event-hooks":-5
    }
  },
  {
    terms:["product dna","product browser","manufacturer product"],
    boosts:{
      "axioglobe-product-normalization":14,
      "axioglobe-bim-data-model":12,
      "axioglobe-search-engineer":10,
      "axioglobe-api-engineer":9,
      "axioglobe-document-intelligence":8
    }
  },
  {
    terms:["gdl engine","gdl object","living object"],
    boosts:{
      "axioglobe-gdl-engine-lead":15,
      "axioglobe-gdl-generator":13,
      "axioglobe-gdl-validation":11,
      "axioglobe-gdl-parameters":10,
      "axioglobe-gdl-geometry":10
    }
  }
];

const activeFeatureSignals = featureSignals.filter(s => s.terms.some(has));

const scored = registry.agents.map(a => {
  let score = 0;
  for (const t of a.tags) if (has(t.replace(/-/g," "))) score += 5;
  if (matchedCategories.includes(a.category)) score += 4;
  if (a.slug === "axioglobe-chief-coordinator") score += 100;
  if (complexity >= 0.40 && /architect/.test(a.rufloType)) score += 3;
  if (/test|fix|debug|build|implement|code/.test(lower) && /tester|debugger|coder|optimizer/.test(a.rufloType)) score += 3;
  if (/review|audit|security|release|production/.test(lower) && /reviewer|tester/.test(a.rufloType)) score += 4;

  for (const signal of activeFeatureSignals) {
    score += signal.boosts?.[a.slug] || 0;
    score += signal.penalties?.[a.slug] || 0;
  }

  return { ...a, matchScore:score };
}).sort((a,b)=>b.matchScore-a.matchScore);

const selected = [];
function add(agent) {
  if (agent && !selected.some(x => x.slug === agent.slug) && selected.length < maxAgents) selected.push(agent);
}

const coordinator = registry.agents.find(a => a.slug === "axioglobe-chief-coordinator");
const qaLead = registry.agents.find(a => a.slug === "axioglobe-qa-lead");
const finalReview = registry.agents.find(a => a.slug === "axioglobe-final-review");
const reservedSlugs = new Set([qaLead?.slug, finalReview?.slug].filter(Boolean));

add(coordinator);

// Reserve the final two slots for QA + final review before filling the squad.
if (complexity >= 0.35 && selected.length < Math.max(1, maxAgents - 2)) {
  add(scored.find(a => a.rufloType === "architect" && a.slug !== coordinator?.slug && !reservedSlugs.has(a.slug)));
}

for (const a of scored) {
  if (selected.length >= Math.max(1, maxAgents - 2)) break;
  if (reservedSlugs.has(a.slug)) continue;
  if (a.matchScore > 0) add(a);
}

add(qaLead);
add(finalReview);

const baseTier = tierFor(complexity);
const reasoning = reasoningFor(complexity);

const reasoningOrder = ["none","low","medium","high","xhigh","max"];
function maxReasoning(a,b) {
  return reasoningOrder.indexOf(a) >= reasoningOrder.indexOf(b) ? a : b;
}
const tierReasoningFloor = { luna:"none", terra:"low", sol:"medium" };

const squad = selected.map(a => {
  const tier = maxTier(baseTier, a.modelFloor);
  let agentReasoning = maxReasoning(reasoning, tierReasoningFloor[tier] || "none");

  if (a.rufloType === "hierarchical-coordinator" || a.rufloType === "architect") {
    agentReasoning = maxReasoning(agentReasoning, "medium");
  }
  if (highRisk && (a.rufloType === "reviewer" || a.rufloType === "tester")) {
    agentReasoning = maxReasoning(agentReasoning, "high");
  }

  return {
    id:a.id,
    slug:a.slug,
    role:a.name,
    rufloType:a.rufloType,
    category:a.category,
    modelTier:tier,
    model:routing.models[tier].id,
    reasoning:agentReasoning,
    matchScore:a.matchScore
  };
});

const plan = {
  task,
  generatedAt:new Date().toISOString(),
  complexity,
  highRisk,
  matchedCategories,
  baseModelTier:baseTier,
  baseModel:routing.models[baseTier].id,
  reasoning,
  squadSize:squad.length,
  maxAgents,
  escalation:routing.escalation,
  squad
};

if (flag("--json")) {
  console.log(JSON.stringify(plan, null, 2));
} else {
  console.log("\\nAxioGlobe Dynamic Agent Plan");
  console.log("============================");
  console.log("Task:", task);
  console.log("Complexity:", complexity);
  console.log("Risk:", highRisk ? "HIGH" : "normal");
  console.log("Base model:", plan.baseModel, "| reasoning:", reasoning);
  console.log("Squad:", squad.length, "/", registry.totalAgents, "registered specialists");
  console.log("");
  for (const a of squad) {
    console.log("-", a.slug, "=>", a.model, "(" + a.reasoning + ")", "[" + a.rufloType + "]");
  }
}

if (flag("--spawn")) {
  console.log("\\nSpawning selected Ruflo squad...");
  for (const a of squad) {
    const result = spawnSync("npx", ["--yes", "ruflo@3.42.0", "agent", "spawn", "-t", a.rufloType, "--name", a.slug], {
      cwd:path.resolve(__dirname, "..", ".."),
      stdio:"inherit",
      shell:process.platform === "win32"
    });
    if (result.status !== 0) {
      console.warn("Spawn warning for", a.slug, "- continuing so one agent cannot block the squad.");
    }
  }
}
