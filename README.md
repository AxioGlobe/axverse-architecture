# Axverse — Archicad V1

Axverse is AxioGlobe's native Archicad intelligence workspace.

**Status:** V1 implementation started  
**Current development branch:** `v1/archicad-foundation`  
**Initial Archicad host target:** Archicad 29 / C++ Add-On SDK

## V1 Product Contract

Axverse V1 contains exactly **18 native Archicad tools** in three permanent categories.

### Design — 6

1. Product DNA Browser
2. Living Object Placement
3. Smart Product Substitute
4. Wall Assembly Builder
5. Smart Openings
6. Space Planner Assist

### Technical — 5

1. Model Health Check
2. Accessibility Checker
3. Daylight Preview
4. Clearance Checker
5. Product Compliance Check

Technical checks are decision-support tools and do not replace professional review.

### Documentation — 7

1. Smart Annotation
2. Smart Dimensioning
3. Drawing Coordinator
4. Schedule Validator
5. Specification Linker
6. Issue Snapshot
7. Publish Package

## Axverse Workspace

The permanent top-level workspace is:

```text
AXVERSE
├── Home / Project Pulse
├── Design
├── Technical
├── Documentation
├── PEER
├── Opportunities
└── Notifications
```

PEER, Project Pulse, AxioScore, AutoBid, identity, messaging and notifications are shared platform capabilities. They are not a fourth Axverse tool category.

## Closed-Beta Wave One

The first six tool flows are:

- Product DNA Browser
- Living Object Placement
- Product Compliance Check
- Specification Linker
- Schedule Validator
- Publish Package

The objective is an end-to-end path from verified product discovery through model placement, compliance/supporting data, coordinated schedules/specifications and publishing.

## Code Now in Development

The first foundation is implemented under:

```text
src/core/
tests/core/
```

`V1ToolRegistry` is the executable source of truth for the V1 tool composition and navigation. Tests enforce:

- 18 total V1 tools
- Design = 6
- Technical = 5
- Documentation = 7
- closed-beta wave one = 6
- unique tool IDs
- permanent Design / Technical / Documentation navigation

This prevents documentation, UI and implementation from silently drifting apart.

## Build the Core on Windows

Prerequisites:

- Visual Studio 2022 with C++ build tools
- CMake 3.19+

Configure:

```powershell
cmake --preset windows-v1-core
```

Build:

```powershell
cmake --build --preset windows-v1-core-debug
```

Test:

```powershell
ctest --preset windows-v1-core-test
```

These core tests do not require the Archicad SDK.

## Archicad Host Integration

The next implementation layer will use Graphisoft's Archicad C++ Add-On Development Kit. Archicad add-ons require the four standard entry points:

- `CheckEnvironment`
- `RegisterInterface`
- `Initialize`
- `FreeData`

The host layer will be kept thin. Product logic, validation and tool contracts should live in testable Axverse core modules where possible.

## Development Sequence

1. V1 core contracts and test harness
2. Archicad 29 add-on host bootstrap
3. Axverse dockable workspace shell
4. Product DNA Browser vertical slice
5. Living Object Placement
6. Product Compliance Check
7. Specification Linker
8. Schedule Validator
9. Publish Package
10. Remaining Design, Technical and Documentation V1 tools

## AI Development Workflow

ChatGPT Desktop Codex is the primary local development executor.

Repository instructions are in `AGENTS.md`. The AxioGlobe 100-agent registry and dynamic router live under `tools/ruflo/`. Codex should use those roles as structured specialist passes while editing and testing the real repository.

The API-billed squad runner remains optional and should not be used unless explicitly requested.

## Company

**AxioGlobe (PTY) Ltd**  
Polokwane, South Africa  
https://axioglobe.co.za
