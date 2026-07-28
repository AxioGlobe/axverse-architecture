# Axverse — ArchiCAD Intelligence Suite

> **Status: Pre-build technical design phase**  
> AxioGlobe is currently designing and architecting the Axverse plugin suite. No code has been written yet. This repository documents the technical architecture, API design, and agent system that will be built.

## Overview

Axverse is a 22-tool ArchiCAD plugin suite that embeds live manufacturer data, AI intelligence, and real-time construction coordination directly inside ArchiCAD. It runs as a dockable panel — architects never leave their software. The intelligence runs underneath the interface they already know.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    ARCHICAD (HOST)                       │
│  ┌─────────────────────────────────────────────────┐    │
│  │           AXVERSE PLUGIN (C++ SDK)              │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │    │
│  │  │ Tool     │  │ Sync     │  │  AI Bridge   │  │    │
│  │  │ Engine   │  │ Engine   │  │  (Claude /   │  │    │
│  │  │ (22      │  │ (IFC /   │  │   Gemini)    │  │    │
│  │  │  tools)  │  │  REST)   │  │              │  │    │
│  │  └────┬─────┘  └────┬─────┘  └──────┬───────┘  │    │
│  └───────┼─────────────┼───────────────┼───────────┘    │
└──────────┼─────────────┼───────────────┼────────────────┘
           │             │               │
    ┌──────▼──────┐  ┌───▼───────┐  ┌───▼──────────────┐
    │ AxioGlobe   │  │ Revit     │  │  Claude API      │
    │ Backend API │  │ Sync      │  │  Gemini API      │
    │ (Cloud Run) │  │ Bridge    │  │  (Vertex AI)     │
    └──────┬──────┘  └───────────┘  └──────────────────┘
           │
    ┌──────▼──────────────────────────────────────────┐
    │              AXIOGLOBE PLATFORM                  │
    │  PostgreSQL · Cloud Storage · n8n Agents (39)   │
    └─────────────────────────────────────────────────┘
```

## The 22 ArchiPower Tools

### Category 1 — Design Intelligence (8 tools)
| # | Tool | AI Engine | Description |
|---|------|-----------|-------------|
| 01 | Live Financial Advisor | Claude Sonnet | Real-time fee entitlement from model value |
| 02 | Automatic Variation Capture | Claude Sonnet | Detects model changes from client instructions |
| 03 | Manufacturer Object Library | Gemini GDL Engine | 76,000+ verified manufacturer BIM objects |
| 04 | Live BOQ Calculator | Claude + Gemini | Real-time bill of quantities from geometry |
| 05 | Space Programme Validator | Claude Sonnet | Room-by-room compliance with client brief |
| 06 | Planning Compliance Checker | Claude (180+ jurisdictions) | Automated planning regulation compliance |
| 07 | Daylighting and Solar Analyser | Gemini (spatial simulation) | Live daylight factor and solar gain analysis |
| 08 | Design Code Navigator | Claude Sonnet | Natural language building code compliance |

### Category 2 — Documentation Intelligence (8 tools)
| # | Tool | AI Engine | Description |
|---|------|-----------|-------------|
| 09 | Smart Drawing Manager | Claude Sonnet | Automatic revision tracking and issue sheets |
| 10 | Specification Generator | Gemini 1.5 Flash | NBS/SABS/CSI spec from model elements |
| 11 | Room Data Sheet Generator | Claude Sonnet | Auto-generated from ArchiCAD room objects |
| 12 | Material Schedule Generator | Claude + Gemini | Live material schedule with manufacturer pricing |
| 13 | Area Schedule Analyser | Claude Sonnet | GIA/NIA/IPMS/RICS all calculated simultaneously |
| 14 | Presentation Package Generator | Gemini (visual) | Full client presentation in 90 minutes |
| 15 | Contract Document Set | Claude + Gemini | Coordinated tender documents from model |
| 16 | Post-Occupation Evaluation | Claude Sonnet | Automated building performance feedback loop |

### Category 3 — Smart Native Tools (6 tools)
| # | Tool | Description |
|---|------|-------------|
| 17 | Smart Delete | Structural check + compartmentation check before deletion |
| 18 | Smart Stretch | Structural capacity check at new span before stretch |
| 19 | Smart Rotate | Solar gain and structural load recalculation on rotation |
| 20 | Smart Cut | Fire compartmentation + acoustic separation check |
| 21 | Smart Paste | Manufacturer data relink + contextual suitability check |
| 22 | Smart Mirror | Handed element detection + correct variant suggestion |

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Plugin | ArchiCAD C++ SDK | Native plugin running inside ArchiCAD |
| AI — Document | Claude Sonnet 4.6 | Code generation, compliance, specification |
| AI — Visual | Gemini 1.5 Flash | GDL object generation, rendering |
| Backend | Google Cloud Run | Containerised API — scales to zero |
| Database | PostgreSQL (Cloud SQL) | Primary data store |
| Storage | Google Cloud Storage | BIM files, manufacturer PDFs |
| Agents | n8n (39 agents) | Workflow orchestration |
| Cross-platform | IFC 4 | Revit-to-ArchiCAD live sync |
| Mobile | React Native | Contractor site app |

## API Design

```
POST /api/v1/gdl/process
  Input: manufacturer_pdf (base64), product_category
  Output: gdl_object (ArchiCAD compatible), metadata, verification_status

POST /api/v1/variation/detect
  Input: model_change_event, project_id, client_instruction_id
  Output: variation_notice_draft, scope_description, quantity

GET /api/v1/boq/live/:project_id
  Output: line_items[], total_cost, currency, last_updated

POST /api/v1/compliance/check
  Input: element_type, dimensions, jurisdiction_code
  Output: compliant (bool), clause_reference, remediation

GET /api/v1/manufacturer/library
  Query: category, country, performance_rating
  Output: products[], gdl_object_url, verified_status
```

## The 39-Agent Orchestration System

AxioGlobe runs 39 AI agents through n8n orchestration. Key agents include:

- **Agent 1 — PA Agent**: Daily briefings, task management, email drafting
- **Agent 8 — Lead Scraper**: Manufacturer and contractor database building
- **Agent 12 — GDL Generator**: PDF to ArchiCAD object pipeline
- **Agent 15 — Compliance Checker**: 180+ jurisdiction code database
- **Agent 23 — Variation Detector**: Model change to variation notice pipeline
- **Agent 31 — Drawing Alert**: ArchiCAD change to contractor notification
- **Agent 39 — Property Connector**: BIM model to property listing pipeline

## Company

**AxioGlobe (PTY) Ltd**  
Registration: 2026/437531/07  
Incorporated: June 2026 — CIPC South Africa  
Headquarters: Polokwane, Limpopo, South Africa  
Website: https://axioglobe.co.za  
Contact: info@axioglobe.co.za  

## Founder

**Tebogo Boshomane** — Founder and CEO  
LinkedIn: https://www.linkedin.com/in/tebogo-boshomane-873468231  

---
*This repository documents planned architecture. AxioGlobe is in pre-build technical design phase.*
