# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Salesforce DX project demonstrating Einstein AI / Agentforce capabilities. It includes:
- Einstein Copilot actions via `@InvocableMethod` Apex classes
- LLM prompt template invocations using `ConnectApi.EinsteinLLM`
- A custom soft drink ordering system with AI-powered recommendations
- FreshDesk external ticket integration

**API version**: 59.0 | **Remote**: https://github.com/Salesforce-Developer9/Einstein-AI.git

## Commands

### LWC / JS Development
```bash
npm run lint                    # ESLint on LWC/Aura JS
npm run test:unit               # Run Jest unit tests
npm run test:unit:watch         # Watch mode
npm run test:unit:coverage      # Coverage report
npm run prettier                # Format all supported files
npm run prettier:verify         # Verify formatting without writing
```

### Deployment & Retrieval

**Priority order — always follow this sequence:**
1. **Salesforce MCP (preferred)** — use `mcp__Salesforce__deploy_metadata` to deploy and `mcp__Salesforce__retrieve_metadata` to retrieve. Use these tools for every deploy/retrieve operation.
2. **SF CLI (fallback only)** — use the commands below *only* if the Salesforce MCP tool call fails or is unavailable:

```bash
sf project deploy start                                              # Deploy to org (fallback)
sf project retrieve start                                            # Pull metadata from org (fallback)
sf org create scratch --def-file config/project-scratch-def.json    # Create scratch org
sf apex run --file scripts/apex/hello.apex                          # Run anonymous Apex
```

## Architecture

All Salesforce metadata lives under `force-app/main/default/`.

### Apex Classes (`classes/`)

| Class | Role |
|---|---|
| `CaseCopilot` | `@InvocableMethod` — creates Cases via Einstein Copilot; calls `TicketSystem` for FreshDesk |
| `AccountSummaryPrompt` | `@InvocableMethod` — aggregates Soft Drink Orders + Cases for Einstein record summary |
| `FlexTemplateController` | Calls `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Customer_Pitch')` with account/product context; used by the LWC |
| `SoftDrinkOrderController` | `@InvocableMethod` — creates `Soft_Drink_Order__c` records |
| `TicketSystem` | HTTP callout to FreshDesk to create external support tickets |
| `CaseUpdates` / `CaseUpdatesDataCloud` | Case update logic and Data Cloud integration |
| `SoftDrinkOrderStatus` | Order status transitions |
| `UserInfoHandler` | User info retrieval |
| `ZipCodeName` | Zip code lookup utility |

### LWC (`lwc/flexTemplateLwc/`)

Single component that calls `FlexTemplateController` to render Einstein LLM prompt template output. Jest tests are in `__tests__/`.

### Custom Objects

- **`Soft_Drink__c`** — product catalog (name, price, rating, quantity, brewery info, etc.)
- **`Soft_Drink_Order__c`** — order records linked to Account and Soft_Drink__c

### Lead Customizations

Custom fields on Lead:
- **`Status_Claude__c`** (Picklist: `Working` / `Not Working`) — populated by `LeadStatusBatch`; visible on Lead Layout
- **`Claude__c`** (Picklist: `Training` / `Test`) — visible on all 4 Lead layouts (Lead, Sales, Support, Marketing), below the `Status` field; read/edit granted to all profiles

**`LeadStatusBatch`** (`classes/LeadStatusBatch.cls`) — batch class that sets `Status_Claude__c` based on `Status`:
- `Status == 'Working - Contacted'` → `Status_Claude__c = 'Working'`
- anything else → `Status_Claude__c = 'Not Working'`

Run via Anonymous Apex: `Database.executeBatch(new LeadStatusBatch(), 200);`

### Lead Layouts

All 4 Lead layouts are now tracked locally under `layouts/`:
- `Lead-Lead Layout.layout-meta.xml`
- `Lead-Lead %28Sales%29 Layout.layout-meta.xml`
- `Lead-Lead %28Support%29 Layout.layout-meta.xml`
- `Lead-Lead %28Marketing%29 Layout.layout-meta.xml`

### Profiles

9 profiles are tracked locally under `profiles/`: Admin, Standard, Custom: Sales/Support/Marketing, Read Only, SolutionManager, ContractManager, MarketingProfile. Field permissions for new Lead fields must be added to all of them.

### Flows (`flows/`)

| Flow | Trigger | What it does |
|---|---|---|
| `Opp_Prospecting_Follow_Up_Task` | Opportunity Create, Stage = Prospecting | Creates two Tasks (due 3 days out): one linked to the Opportunity, one to the related Account |
| `Create_a_Task_Flow` | AutoLaunched (input vars) | Generic task creator; accepts `relatedId` and `subject` input variables |
| `Initiate_Return` | — | Order return initiation |
| `Update_Soft_Drink_Flow` | — | Updates Soft Drink records |

### Key Patterns

- Einstein Copilot actions are Apex classes with `@InvocableMethod` — they receive structured input/output lists and are registered as copilot actions in the org.
- LLM calls go through `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(templateName, inputParams)` — prompt templates are managed in the org (not in this repo).
- External integration (FreshDesk) is handled via named credentials / HTTP callouts in `TicketSystem.cls`.

### Deployment Manifest

`manifest/package.xml` controls what is deployed. Edit it when adding/removing metadata types from deployments.

> When deploying, always prefer `mcp__Salesforce__deploy_metadata` over the SF CLI. Use the CLI only if the MCP tool is unavailable.
