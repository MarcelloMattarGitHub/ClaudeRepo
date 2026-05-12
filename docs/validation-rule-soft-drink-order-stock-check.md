# Soft Drink Order Stock Check Validation Rule

**Date:** 2026-05-12
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request
Create a validation rule on `Soft_Drink_Order__c` that blocks saving an order when:
1. The related Soft Drink's `Status__c` is `'Expired'`, OR
2. The `Quantity__c` ordered is greater than the Soft Drink's `Quantity_Left__c`

### Business Objective
Prevents users from placing orders against soft drinks that are either past their expiry date or do not have sufficient stock remaining. Without this guard, an order could be saved against an expired product or one with zero units available, leading to fulfillment failures and data integrity issues.

### Summary
A single declarative validation rule — `Prevent_Expired_Or_Insufficient_Stock` — was added to the `Soft_Drink_Order__c` object. The rule uses a cross-object formula to inspect the parent `Soft_Drink__c` record at save time and blocks the transaction if either the product is expired or the requested quantity exceeds available stock. No Apex code or Flow was required.

---

## Components Created

### Admin Components (Declarative)

#### Validation Rules

| Object | Rule API Name | Active | Description |
|--------|---------------|--------|-------------|
| `Soft_Drink_Order__c` | `Prevent_Expired_Or_Insufficient_Stock` | Yes | Blocks order save when the linked Soft Drink is Expired or has insufficient stock |

---

### Development Components (Code)

None. This task was implemented entirely with a declarative validation rule.

---

## Validation Rule Details

### Error Condition Formula

```
OR(
    Soft_Drink__r.Status__c = 'Expired',
    Quantity__c > Soft_Drink__r.Quantity_Left__c
)
```

The formula returns `true` (and blocks the save) when either condition is met:

| Condition | Fields Involved | Logic |
|-----------|-----------------|-------|
| Expired product | `Soft_Drink__r.Status__c` | Blocks if parent Status equals `'Expired'` |
| Insufficient stock | `Quantity__c`, `Soft_Drink__r.Quantity_Left__c` | Blocks if ordered quantity exceeds units remaining |

### Error Message Displayed to User

> "Cannot save this order: the Soft Drink is either Expired or does not have enough stock to fulfill the requested quantity."

The message is shown inline on the record form and applies to both UI saves and API/programmatic inserts/updates.

---

## Data Flow

### How It Works

```
1. User attempts to save a Soft_Drink_Order__c record (insert or update).
2. Salesforce evaluates the validation rule formula before committing the DML.
3. The formula traverses the Master-Detail relationship via the Soft_Drink__r
   cross-object reference to read two fields on the parent Soft_Drink__c:
     a. Status__c  — picklist ("Safe to Use" | "Expired")
     b. Quantity_Left__c — formula field (Total_Quantity__c - Quantity_Used__c)
4. If either sub-condition is true, the OR() returns true.
5. Salesforce blocks the save and displays the error message to the user.
6. If both sub-conditions are false, the save proceeds normally.
```

### Field Dependency Chain

```
Soft_Drink_Order__c.Quantity__c   (Number, precision 18, scale 0)
         |
         | compared against
         v
Soft_Drink__c.Quantity_Left__c    (Formula Number)
         = Total_Quantity__c  (Number, precision 5, scale 0)
           - Quantity_Used__c (Roll-Up Summary: SUM of Soft_Drink_Order__c.Quantity__c)

Soft_Drink__c.Status__c           (Restricted Picklist)
         values: "Safe to Use" | "Expired"
```

### Architecture Diagram

```
┌────────────────────────────────┐
│   User / API caller            │
│   (saves Soft_Drink_Order__c)  │
└───────────────┬────────────────┘
                │ DML attempt
                ▼
┌────────────────────────────────────────────────────────────┐
│  Validation Rule: Prevent_Expired_Or_Insufficient_Stock    │
│  (fires before commit, on insert and update)               │
│                                                            │
│  OR(                                                       │
│    Soft_Drink__r.Status__c = 'Expired'          ──────┐   │
│    Quantity__c > Soft_Drink__r.Quantity_Left__c  ─────┤   │
│  )                                                     │   │
└──────────────────────┬─────────────────────────────────┘   │
           FALSE       │         TRUE                        │
     (both conditions  │    (either condition                │
        are false)     │       is true)                      │
                       │                                     │
         ┌─────────────┴──────────────┐                      │
         ▼                            ▼                       │
  Save proceeds              Error returned to user:         │
  normally                   "Cannot save this order..."     │
                                                             │
┌────────────────────────────┐                               │
│  Soft_Drink__c (parent)    │◀──── cross-object lookup ─────┘
│  Status__c (Picklist)      │      via Soft_Drink__r
│  Quantity_Left__c (Formula)│
│  = Total_Quantity__c       │
│    - Quantity_Used__c      │
│      (Roll-Up Summary)     │
└────────────────────────────┘
```

---

## File Locations

| Component | Path |
|-----------|------|
| Validation Rule metadata | `force-app/main/default/objects/Soft_Drink_Order__c/validationRules/Prevent_Expired_Or_Insufficient_Stock.validationRule-meta.xml` |
| Soft Drink Order object | `force-app/main/default/objects/Soft_Drink_Order__c/` |
| Soft Drink object | `force-app/main/default/objects/Soft_Drink__c/` |

---

## Object Relationship Reference

### Soft_Drink_Order__c Fields Involved

| Field API Name | Label | Type | Required | Notes |
|----------------|-------|------|----------|-------|
| `Soft_Drink__c` | Soft Drink | Master-Detail (to `Soft_Drink__c`) | Yes | Relationship order 0; sharing model ControlledByParent |
| `Quantity__c` | Quantity | Number (18, 0) | No | Units the customer wants to order |

### Soft_Drink__c Fields Referenced (via cross-object formula)

| Field API Name | Label | Type | Notes |
|----------------|-------|------|-------|
| `Status__c` | Status | Restricted Picklist | Values: "Safe to Use", "Expired" |
| `Quantity_Left__c` | Quantity Left | Formula (Number) | `Total_Quantity__c - Quantity_Used__c`; blanks treated as zero |
| `Total_Quantity__c` | Total Quantity | Number (5, 0) | Manually set total stock |
| `Quantity_Used__c` | Quantity Used | Roll-Up Summary | SUM of `Soft_Drink_Order__c.Quantity__c` grouped by `Soft_Drink__c` |

### Object Sharing Model

`Soft_Drink_Order__c` uses **ControlledByParent** sharing (both internal and external), consistent with a Master-Detail relationship to `Soft_Drink__c`. Record-level access to an order is always determined by the parent Soft Drink record.

---

## Testing

### Test Scenarios

Because this is a declarative validation rule (no Apex), formal Apex test coverage is not required. However, the following scenarios should be verified with manual or automated UI/API tests before and after deployment:

| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | Order with `Quantity__c = 5`, parent `Status__c = 'Safe to Use'`, `Quantity_Left__c = 10` | Save succeeds |
| 2 | Order with `Quantity__c = 5`, parent `Status__c = 'Expired'`, `Quantity_Left__c = 10` | Save blocked — expired |
| 3 | Order with `Quantity__c = 15`, parent `Status__c = 'Safe to Use'`, `Quantity_Left__c = 10` | Save blocked — insufficient stock |
| 4 | Order with `Quantity__c = 15`, parent `Status__c = 'Expired'`, `Quantity_Left__c = 10` | Save blocked — both conditions true |
| 5 | Order with `Quantity__c = 10`, parent `Quantity_Left__c = 10` | Save succeeds — exact match is allowed (not strictly greater than) |
| 6 | Programmatic API insert hitting the same conditions as above | Same blocking behavior — validation rules apply to all DML regardless of source |

---

## Security

### Validation Rule Scope
Validation rules fire for all users regardless of profile or permission set. There is no bypass mechanism built into this rule. If an admin or integration user needs to bypass it in future, a custom bypass field (e.g., `Bypass_Validation__c`) and an additional `AND(NOT(...))` clause would need to be added.

### Sharing Model Impact
The cross-object formula reads from the parent `Soft_Drink__c` record. Because the relationship is Master-Detail, the child record's visibility is always controlled by the parent — a user who has access to a `Soft_Drink_Order__c` record will always have read access to the parent `Soft_Drink__c` fields referenced in the formula.

---

## Notes & Considerations

### Known Limitations

- **Race condition on stock:** `Quantity_Left__c` is a formula that depends on the roll-up summary `Quantity_Used__c`. Roll-up summaries are recalculated asynchronously in some bulk scenarios. In high-concurrency inserts, two simultaneous orders might both pass the validation (both see the pre-insert `Quantity_Left__c`) and together exceed available stock. If strict stock reservation is required, an Apex trigger with row-locking (`FOR UPDATE`) would be more reliable.
- **No partial quantity check on update:** If an existing order's quantity is edited upward, the rule fires again and will block the update if the new quantity exceeds available stock — this is the intended behavior.
- **Blank `Quantity__c`:** The `Quantity__c` field is not marked required. If `Quantity__c` is null, the comparison `null > Quantity_Left__c` evaluates to `false` in Salesforce formula logic, so the insufficient-stock condition will not trigger on a blank quantity.

### Future Enhancements

- Add a required constraint or a separate validation rule to enforce that `Quantity__c` is not null or zero before saving.
- Consider an Apex trigger with `FOR UPDATE` row locking if the business requires strict prevention of overselling under concurrent load.
- A Flow or Process could proactively show stock availability on the order form before the user attempts to save.

### Dependencies

| Dependency | Type | Why It Matters |
|------------|------|----------------|
| `Soft_Drink__c.Status__c` picklist value `'Expired'` | Picklist value | If this value is renamed or removed, the formula will silently stop blocking expired products |
| `Soft_Drink__c.Quantity_Left__c` formula | Formula field | If the formula is changed or the field is deleted, the stock check breaks |
| `Soft_Drink__c.Quantity_Used__c` roll-up | Roll-Up Summary | Feeds `Quantity_Left__c`; removing it cascades to the validation rule |
| Master-Detail relationship `Soft_Drink_Order__c.Soft_Drink__c` | Relationship | Cross-object formula (`Soft_Drink__r`) depends on this relationship existing |

---

## Change History

| Date | Author | Change Description |
|------|--------|--------------------|
| 2026-05-12 | Documentation Agent | Initial creation |
