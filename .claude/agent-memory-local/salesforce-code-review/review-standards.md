---
name: review-standards
description: Agreed review thresholds and standards for this project
metadata:
  type: feedback
---

**Wire Error Handling in LWC:** Flag missing wire `error` property handling as a WARNING (not CRITICAL) when the component has no user-facing error state. The component still loads gracefully (shows nothing), but best practice is to surface an error message to the user.

**Why:** Missing wire error handling degrades user experience but does not cause data corruption or security issues. The wire adapter silently fails without an error branch.

**How to apply:** Rate as WARNING in LWC reviews.

---

**`if:true` vs `lwc:if` directive:** In API 59.0, `if:true` is still valid and not deprecated. The `lwc:if` directive was introduced as preferred in later API versions. Flag use of `if:true` at API 59.0 as a SUGGESTION only (forward compatibility).

**Why:** `if:true` is not deprecated at 59.0, just flagged as legacy going forward.

**How to apply:** SUGGESTION level finding, not WARNING or CRITICAL.

---

**@TestSetup absence in test classes:** Absence of @TestSetup is acceptable when each test method builds its own isolated data (helper method pattern). Flag as SUGGESTION only — not a WARNING — when test data isolation is otherwise maintained.

**Why:** @TestSetup improves performance for large test suites but is not required. The helper-method pattern achieves the same isolation goal.

**How to apply:** SUGGESTION if test data is otherwise isolated.

---

**Recursion prevention:** For triggers that ONLY write to the current record's fields in before context (no re-DML on the same object), a static recursion flag is not required. Flag absence of recursion guard as WARNING only when the after-context performs DML on the same SObject, which could re-trigger the same trigger.

**Why:** AccountTrigger after-context inserts Tasks (different SObject), not Accounts, so re-entry is not a risk.

**How to apply:** No recursion guard needed for this pattern. Do not flag.
