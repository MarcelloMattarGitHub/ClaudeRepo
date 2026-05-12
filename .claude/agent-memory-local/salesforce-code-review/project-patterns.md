---
name: project-patterns
description: Intentional conventions for this Salesforce project — use to avoid flagging correct patterns as issues
metadata:
  type: project
---

**API Version:** 59.0 (set in sfdx-project.json sourceApiVersion). CLAUDE.md mentions 65.0 but sfdx-project.json is authoritative at 59.0. Do not flag 59.0 metadata as outdated until confirmed otherwise.

**Why:** sfdx-project.json sourceApiVersion drives deployments; CLAUDE.md reference to 65.0 appears to be aspirational/documentation drift.

**How to apply:** Accept apiVersion 59.0 in all metadata files without flagging it as a mismatch.

---

**Trigger Pattern:** Handler pattern — trigger contains routing only, all logic in handler class. This matches the existing LeadTrigger / LeadTriggerHandler convention and AccountTrigger / AccountTriggerHandler follows the same approach. Do NOT flag this as missing logic separation.

**Why:** Explicitly documented in CLAUDE.md and design-requirements.md.

**How to apply:** A trigger that only calls handler static methods is correct; no need to recommend moving routing logic.

---

**DML Security:** `Database.insert(list, AccessLevel.USER_MODE)` is the project's chosen pattern for USER_MODE enforcement on DML (API 59.0 feature). Do not flag as missing security.

**Why:** AccessLevel.USER_MODE in DML was introduced in API 58.0 and is the correct alternative to WITH USER_MODE in SOQL for DML operations.

**How to apply:** Accept `Database.insert(list, AccessLevel.USER_MODE)` as correct FLS/CRUD enforcement.

---

**LWC Wire-only Pattern:** LWC components that use only `@wire(getRecord)` without an Apex controller are intentional. The design spec explicitly prohibits adding an Apex controller for the accountHealthCard LWC.

**Why:** Documented in design-requirements.md as a confirmed decision.

**How to apply:** Do not flag absence of Apex controller for wire-only LWC components as a missing pattern.

---

**Before-context Health Rating:** The AccountTriggerHandler uses both before insert/update (to write Health_Rating__c on the record directly, avoiding extra DML) and after insert/update (to create Tasks). The trigger correctly fires on before insert, before update, after insert, after update. This is intentional and architecturally sound.

**How to apply:** Do not flag before-context field writing as a pattern violation.
