# Axverse — AxioGlobe Design & BIM Surface

> **Status: architecture / pre-production design**
>
> This repository documents Axverse as one external surface of the unified AxioGlobe construction-intelligence platform. It does **not** represent the whole AxioGlobe product and should not be read as a standalone 22-tool AI suite.

## Position in the AxioGlobe ecosystem

AxioGlobe is one platform with a shared identity, entity model, project graph, Product DNA, evidence, permissions, events and audit history.

The primary external surfaces are:

- **Axverse** — architect / engineer BIM and design interface
- **Axio Supply** — manufacturer and supplier surface
- **Axio Build** — contractor / delivery / commercial surface
- **PEER** — authenticated work-connected construction network and operating layer

Internal capabilities such as Product DNA, validation, Product Intelligence, Project Pulse, AutoBid, AxioDocs, jobs/execution, matching and scoring are shared platform services rather than separate disconnected products.

## Axverse V1 information architecture

Axverse V1 keeps three permanent categories and **18 tools**.

### Design — 6
1. Product DNA Browser
2. Living Object Placement
3. Smart Product Substitute
4. Wall Assembly Builder
5. Smart Openings
6. Space Planner

### Technical — 5
1. Model Health Check
2. Accessibility Checker
3. Daylight Preview
4. Clearance Checker
5. Product Compliance Check

### Documentation — 7
1. Smart Annotation
2. Smart Dimensioning
3. Drawing Coordinator
4. Schedule Validator
5. Specification Linker
6. Issue Snapshot
7. Publish Package

PEER, Project Pulse, Opportunities and Notifications sit around Axverse as platform services; they are not a fourth Axverse category.

## V1 execution principle

The immediate objective is **not** to build all 18 tools at equal depth.

The first production-quality proof is the end-to-end construction-intelligence loop:

1. Manufacturer or supplier data enters AxioGlobe.
2. AxioGlobe creates or updates canonical Product DNA.
3. Validation checks the record and linked BIM content.
4. A persistent job tracks processing.
5. Axverse authenticates the user and project inside Archicad.
6. Project Health Scan / Model Health capabilities read project and product intelligence.
7. AxioGlobe identifies a real issue, inconsistency or missing fact.
8. Evidence is shown and a safe action or repair is proposed.
9. Human approval is required at consequential boundaries.
10. Approved work is executed or routed for more information.
11. Decision, evidence and outcome are recorded.
12. PEER/platform associates the manufacturer, product, project and participant context.

The first 5–7 capabilities should become reliable end-to-end before the remaining V1 tools are broadened.

## Shared core

Axverse consumes the same AxioGlobe Core used by the other surfaces:

- Identity, organisations and permissions
- Projects and project graph
- Products and canonical Product DNA
- BIM objects and derived artifacts
- Validation, issues, decisions, actions and approvals
- Evidence and outcome history
- Events and notifications
- Jobs / controlled execution
- Relevance, matching and trust intelligence

## BIM execution environments

- **Archicad** is the first professional execution environment.
- **Revit** is a later shared-core client using the same canonical cloud truth.
- GDL/GSM, Revit families, IFC and web/API representations are **derived artifacts**, not the canonical product record.

## Engineering principles

- Product DNA is canonical and software-neutral.
- AI may interpret and propose; deterministic systems enforce schema, calculations, permissions and release gates.
- Missing or conflicting source data must become a visible exception rather than an invented value.
- Consequential actions require explicit approval.
- Decisions and outcomes must be auditable.
- Public capability claims must match demonstrated repository evidence and tests.

## Current priority

1. Platform foundation
2. Product DNA
3. Lightweight jobs / execution
4. Validation
5. Axverse Project Health / Model Health proof
6. Evidence, approval and audit
7. PEER connection
8. Remaining Axverse V1 capabilities

## Repository scope

This repository is a **public architecture reference** for Axverse. Production application code, credentials, customer data and proprietary implementation details must not be placed here.

---
AxioGlobe (Pty) Ltd · South Africa · https://axioglobe.co.za
