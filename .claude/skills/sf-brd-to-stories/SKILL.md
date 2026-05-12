---
name: sf-brd-to-stories
description: "Parses a BRD/FRD/Requirements PDF document and generates Salesforce-specific user stories with component mapping, complexity estimation, and effort sizing in a formatted Excel workbook. Use this skill when the user says 'parse this BRD', 'generate user stories from this document', 'create stories from requirements', 'analyze this BRD for Salesforce', 'convert requirements to user stories', or drops a BRD/FRD PDF and wants Salesforce implementation planning. Also trigger when user mentions requirement extraction, story mapping, effort estimation from a requirements document, or sprint planning from a BRD."
---

# BRD to Salesforce User Stories Generator

## Purpose

Takes a BRD/FRD PDF document, extracts every requirement, maps each to Salesforce components with implementation details, estimates complexity and effort, and generates a sprint-ready Excel workbook — all without the developer reading the full document.

## Prerequisites

- Python 3.x with `pdfplumber` and `openpyxl`
  ```bash
  pip install pdfplumber openpyxl --break-system-packages
  ```
- A BRD/FRD PDF document in the project (or uploaded)

## Execution Flow

### Phase 1: Extract Requirements (Python)

Run the extraction script:

```bash
python3 .claude/skills/sf-brd-to-stories/scripts/parse_brd.py \
  --pdf "{path_to_brd_pdf}" \
  --output "{project_root}/brd-analysis/extracted-requirements.json"
```

**What the script does:**
1. Extracts full text from every page using `pdfplumber`
2. Detects requirement statements using multiple patterns:
   - Explicit IDs: `REQ-001`, `FR-01`, `BR-1.1`, `UC-01`
   - Keyword starters: "The system shall", "The system must", "Users should be able to", "The application will"
   - Numbered requirements: `1.1`, `1.2.3`, `a)`, `i.`
   - Section-based: Detects heading patterns and groups requirements under them
3. Extracts for each requirement: ID, raw text, section context, page number, detected priority keywords
4. Outputs a structured JSON file

**After this step:** Read the output JSON. If extraction looks incomplete (too few requirements for a large document), manually review the PDF sections. The script is pattern-based — unusual BRD formats may need manual assistance.

### Phase 2: Salesforce Mapping (Claude + Skill Knowledge)

**READ the reference file first:**
```
.claude/skills/sf-brd-to-stories/references/sf-mapping-rules.md
```

This file contains the Salesforce component mapping rules, complexity matrix, and acceptance criteria templates that power this skill. These rules encode Deloitte Salesforce practice standards — they are NOT general LLM knowledge.

For EACH extracted requirement, determine:

1. **User Story**: Convert to standard format:
   ```
   As a [persona from BRD context],
   I want to [action derived from requirement],
   So that [business value from requirement context]
   ```

2. **Salesforce Component**: Map to one or more of:
   - Configuration (Object/Field/Page Layout/Record Type/Validation Rule)
   - Flow (Screen Flow / Record-Triggered / Scheduled / Autolaunched)
   - Apex (Trigger / Batch / Queueable / REST Integration / LWC Controller)
   - LWC (Custom Component / Override / Quick Action)
   - Integration (REST / SOAP / Platform Event / CDC / Middleware)
   - Security (Profile / Permission Set / Sharing Rule / OWD)
   - Reporting (Report / Dashboard / Report Type)
   - AppExchange (Managed Package recommendation)

3. **Complexity**: Apply the rules from `sf-mapping-rules.md`:
   - **Simple** (1-2 SP): Field addition, validation rule, simple flow, report
   - **Medium** (3-5 SP): Screen flow with decisions, record-triggered flow, LWC with wire, custom object with relationships
   - **Complex** (8-13 SP): Apex integration, batch processing, multi-object transaction, complex LWC with state management
   - **Epic** (13+ SP): External system integration, data migration, complex security model, multi-cloud solution

4. **Acceptance Criteria**: Generate Salesforce-specific ACs (not generic). Use templates from the mapping rules:
   - "Given [precondition], When [action in SF UI], Then [expected Salesforce behavior]"
   - Include Salesforce-specific details: "record type should be set to X", "validation rule fires when Y", "flow assigns owner based on Z"

5. **Dependencies**: Identify cross-requirement dependencies (e.g., "needs custom object from REQ-003 before this field can be created")

6. **Sprint Grouping**: Suggest logical sprint grouping based on dependencies:
   - Sprint 1: Data Model (objects, fields, relationships)
   - Sprint 2: Security & Access (profiles, permission sets, sharing)
   - Sprint 3: Automation (flows, process builders, triggers)
   - Sprint 4: UI (page layouts, LWC, screen flows)
   - Sprint 5: Integration (APIs, middleware, external systems)
   - Sprint 6: Reporting & Analytics (reports, dashboards)

Write the enriched data to: `brd-analysis/enriched-requirements.json`

### Phase 3: Generate Excel (Python)

```bash
python3 .claude/skills/sf-brd-to-stories/scripts/generate_excel.py \
  --input "{project_root}/brd-analysis/enriched-requirements.json" \
  --output "{project_root}/brd-analysis/User_Stories_{project_name}.xlsx"
```

**The Excel contains these sheets:**

1. **User Stories** (main sheet):
   | Req ID | Section | Requirement | User Story | SF Component | Complexity | Story Points | Sprint | Acceptance Criteria | Dependencies | Notes |

2. **Effort Summary**:
   | Sprint | Total Stories | Simple | Medium | Complex | Epic | Total SP | Estimated Days |

3. **Component Breakdown**:
   | Component Type | Count | Total SP | Examples |

4. **Risks & Assumptions**:
   | # | Risk/Assumption | Impact | Mitigation | Related Reqs |

### Phase 4: Present Results

After generating the Excel, provide the developer a summary:

```
BRD Analysis Complete: {brd_name}

📊 Requirements Extracted: {count}
📋 User Stories Generated: {count}
⏱️  Total Story Points: {sum}
🏃 Suggested Sprints: {count}

Breakdown:
  Simple (1-2 SP):   {count} stories
  Medium (3-5 SP):   {count} stories
  Complex (8-13 SP): {count} stories
  Epic (13+ SP):     {count} stories

SF Components Used:
  Configuration:     {count}
  Flows:             {count}
  Apex:              {count}
  LWC:               {count}
  Integration:       {count}
  Security:          {count}

📄 Excel: brd-analysis/User_Stories_{name}.xlsx
```

## Directory Structure

```
.claude/skills/sf-brd-to-stories/
├── SKILL.md                              ← This file
├── scripts/
│   ├── parse_brd.py                      ← PDF → JSON extractor
│   └── generate_excel.py                 ← JSON → formatted Excel
└── references/
    └── sf-mapping-rules.md               ← Salesforce component mapping rules

project-root/
└── brd-analysis/                         ← Generated outputs
    ├── extracted-requirements.json       ← Phase 1 output
    ├── enriched-requirements.json        ← Phase 2 output
    └── User_Stories_ProjectName.xlsx     ← Final deliverable
```
