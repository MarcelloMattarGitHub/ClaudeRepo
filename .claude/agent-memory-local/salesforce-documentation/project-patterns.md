---
name: project-patterns
description: Recurring architecture patterns and conventions in this Salesforce DX project (AgentForce)
metadata:
  type: project
---

## Trigger Handler Pattern

All triggers in this project follow the handler pattern: the trigger file contains only routing logic (calling static methods on the handler class), and all business logic lives in the handler class. Existing examples: LeadTrigger / LeadTriggerHandler, AccountTrigger / AccountTriggerHandler.

**Why:** Keeps triggers thin and testable; business logic is in a class that can be called from tests directly.

**How to apply:** When documenting new triggers, always note the separation — the trigger routes, the handler acts. Document both the trigger events and the corresponding handler methods together.

## Security Conventions

- Handler classes: `public with sharing`
- DML in handlers: `Database.insert(list, AccessLevel.USER_MODE)` (API 57.0+)
- LWC data access: `@wire(getRecord)` from `lightning/uiRecordApi` — respects FLS automatically; no Apex controller needed for read-only display components

## API Version

Project `sourceApiVersion` is `59.0` (confirmed in `sfdx-project.json`). CLAUDE.md references 65.0 as the target API version for new components — trust CLAUDE.md for intended API version, `sfdx-project.json` for the current project file value. Package directory: `force-app/main/default`. Project name: AgentForce.

## Design Requirements File

The design agent always writes to `agent-output/design-requirements.md`. This is the authoritative source for the original user request, field API names, and component specifications. Always read this file first when creating documentation.

## Task Creation Pattern

When Apex creates Tasks in response to a trigger event, the pattern is: collect Task objects in a list inside the loop, then do a single `Database.insert` after the loop — never inside the loop. This is the bulk-safe pattern used throughout this project.
