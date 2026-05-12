---
name: trigger-handler-test-patterns
description: Proven patterns for testing before/after insert+update trigger handlers with transition rules and bulk processing
metadata:
  type: feedback
---

## Trigger Handler Test Patterns (confirmed on AccountTriggerHandler)

### Before Insert
- Insert the record directly; the trigger fires automatically — no need to call handler methods directly.
- Always query back after insert/update to get the persisted field values, not the in-memory object.

### Before Update guard (only re-evaluate when specific fields change)
- To test the "no re-eval" path: insert with known values, then update ONLY an unrelated field (e.g., Phone). Verify the rating stays unchanged.
- To test the "re-eval" path: change AnnualRevenue or NumberOfEmployees in the update.

### Transition-based Task creation (afterUpdate)
- The transition rule is: new rating == 'At Risk' AND old rating != 'At Risk'.
- Four distinct scenarios to cover:
  1. Good → At Risk: Task created (happy path)
  2. Average → At Risk: Task created (not just from Good)
  3. At Risk → At Risk (stays): No Task created
  4. At Risk → Good: No Task created
- Always verify Task field values (Subject format, Priority, Status, ActivityDate, WhatId).

### Bulk test (200 records)
- Insert 200 records first (inside startTest if needed for governor limit reset).
- Then update all 200 in a single DML to trigger the transition.
- Query Tasks with `WHERE WhatId IN :accountIdList` to count results.
- Verify count == 200 AND spot-check Priority/Status on each.

### Boundary conditions for threshold comparisons
- Always test exact-equal values on thresholds when the condition is strictly > or <.
- Revenue == 10,000,000 → Average (not Good, since condition is > not >=).
- Revenue == 1,000,000 → Average (not At Risk, since condition is < not <=).

### General
- Use `Assert.areEqual(expected, actual, 'message')` — not `System.assertEquals`.
- Always include a descriptive assertion message explaining what *should* happen.
- Wrap DML inside `Test.startTest() / Test.stopTest()` to reset governor limits.
- Use a private static `buildAccount(name, revenue, employees)` helper to reduce boilerplate.

**Why:** Confirmed working against AccountTriggerHandler.cls in May 2026 session.
**How to apply:** Reuse these patterns for any future trigger handler test class in this project.
