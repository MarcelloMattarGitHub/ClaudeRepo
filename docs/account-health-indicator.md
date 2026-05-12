# Account Health Indicator

**Date:** 2026-05-12
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Build an "Account Health Indicator" feature on the Account object consisting of:

1. A picklist field that stores a health rating (Good / Average / At Risk).
2. A datetime field that records when the rating was last evaluated.
3. An Apex trigger (with handler) that automatically evaluates health ratings on insert and update, and creates a follow-up Task when an Account's health rating transitions from a non-At-Risk value to "At Risk".
4. A Lightning Web Component that displays the current health rating on the Account record page as a color-coded badge, along with the last-evaluated timestamp.

### Business Objective

Account managers need a quick, consistent signal for which accounts require immediate attention. Instead of manually reviewing revenue and headcount figures across hundreds of accounts, the health indicator automatically classifies each account as Good, Average, or At Risk the moment it is created or updated. When an account crosses into At Risk territory, a high-priority follow-up task is automatically assigned to the account owner so that no at-risk relationship falls through the cracks.

### Summary

The feature adds two custom fields to the Account object, an Apex trigger with a handler class that evaluates health ratings in real time and creates tasks on critical transitions, and a Lightning Web Component that renders a color-coded badge on the Account Record Page. All evaluation logic runs declaratively on save — no manual steps are required from users.

---

## Components Created

### Admin Components (Declarative)

#### Custom Fields

| Object | Field API Name | Type | Label | Required | Default |
|--------|----------------|------|-------|----------|---------|
| `Account` | `Health_Rating__c` | Picklist (Restricted) | Health Rating | No | Average |
| `Account` | `Health_Rating_Last_Evaluated__c` | DateTime | Health Rating Last Evaluated | No | — |

**Health_Rating__c picklist values (in order):**

| Value | Default |
|-------|---------|
| Good | No |
| Average | Yes |
| At Risk | No |

The picklist is restricted, meaning users cannot enter free-text values — only the three defined values are allowed.

---

### Development Components (Code)

#### Apex Triggers

| Trigger Name | Object | Events | Description |
|--------------|--------|--------|-------------|
| `AccountTrigger` | `Account` | before insert, before update, after insert, after update | Routes all trigger events to AccountTriggerHandler. Contains no business logic. |

#### Apex Classes

| Class Name | Type | Description |
|------------|------|-------------|
| `AccountTriggerHandler` | Trigger Handler | Evaluates health ratings (before context) and creates At Risk tasks (after context). All business logic lives here. |

#### Test Classes

| Test Class | Tests For | Methods | Coverage |
|------------|-----------|---------|----------|
| `AccountTriggerHandlerTest` | `AccountTriggerHandler` + `AccountTrigger` | 14 | ~95%+ |

#### Lightning Web Components

| Component Name | Location | Description |
|----------------|----------|-------------|
| `accountHealthCard` | `force-app/main/default/lwc/accountHealthCard/` | Displays the health rating badge and last-evaluated timestamp on the Account Record Page. Reads data via `@wire(getRecord)` — no Apex controller. |

---

## Health Rating Rules

The rating is calculated from `AnnualRevenue` and `NumberOfEmployees`. Both conditions must be satisfied for a non-Average rating. All thresholds are strict (not inclusive). Null values fall through to Average by design.

| Rating | Condition |
|--------|-----------|
| **Good** | `AnnualRevenue > $10,000,000` AND `NumberOfEmployees > 500` |
| **At Risk** | `AnnualRevenue < $1,000,000` AND `NumberOfEmployees < 100` |
| **Average** | Everything else — including nulls, partial matches, and exact boundary values |

**Boundary behavior:**

- `AnnualRevenue = $10,000,000` with employees > 500 → Average (not Good; condition is strictly greater than)
- `AnnualRevenue = $1,000,000` with employees < 100 → Average (not At Risk; condition is strictly less than)
- Revenue meets Good threshold but employees does not → Average
- Revenue meets At Risk threshold but employees does not → Average

---

## Data Flow

### Insert Flow

```
User creates Account record
         |
         v
  AccountTrigger fires (before insert)
         |
         v
  AccountTriggerHandler.beforeInsert()
    - Calls applyHealthRating() for each Account
    - calculateHealthRating(AnnualRevenue, NumberOfEmployees)
    - Sets Health_Rating__c and Health_Rating_Last_Evaluated__c
    - No DML needed — before context writes directly to the record
         |
         v
  AccountTrigger fires (after insert)
         |
         v
  AccountTriggerHandler.afterInsert()
    - No action (Task creation does not apply on insert)
         |
         v
  Record saved to database with Health_Rating__c populated
         |
         v
  accountHealthCard LWC renders badge on Record Page
```

### Update Flow

```
User updates Account record
         |
         v
  AccountTrigger fires (before update)
         |
         v
  AccountTriggerHandler.beforeUpdate()
    - For each Account, compares AnnualRevenue and NumberOfEmployees to oldMap
    - If either field changed: calls applyHealthRating() → re-evaluates rating
    - If neither changed: skips re-evaluation (performance guard)
         |
         v
  AccountTrigger fires (after update)
         |
         v
  AccountTriggerHandler.afterUpdate()
    - For each Account where:
        old.Health_Rating__c != 'At Risk'
        AND new.Health_Rating__c == 'At Risk'
      → Build a Task record
    - After loop: single bulk DML insert for all collected Tasks
         |
         v
  Record saved, Task(s) created, badge on Record Page reflects new rating
```

### Architecture Diagram

```
┌──────────────────────┐    insert/update    ┌──────────────────────┐
│   User / API Call    │────────────────────▶│  Account Record      │
│                      │                     │  AnnualRevenue       │
└──────────────────────┘                     │  NumberOfEmployees   │
                                             └──────────┬───────────┘
                                                        │
                                    ┌───────────────────┼───────────────────┐
                                    │  AccountTrigger   │                   │
                                    │  (routing only)   │                   │
                                    └───────────────────┘                   │
                                             │                              │
                          ┌──────────────────┼──────────────────┐          │
                          │                  │                  │          │
                          ▼                  ▼                  ▼          │
                   beforeInsert       beforeUpdate        afterUpdate       │
                          │                  │                  │          │
                          └──────────────────┘                  │          │
                                    │                           │          │
                                    ▼                           ▼          │
                          applyHealthRating()         Transition check      │
                          calculateHealthRating()     (non-At-Risk →        │
                          Sets Health_Rating__c        At Risk only)        │
                          Sets Last_Evaluated__c               │            │
                                    │                           ▼           │
                                    │                     Task insert       │
                                    │                     (bulk DML)        │
                                    │                                       │
                                    └───────────────────────────────────────┘
                                                        │
                                                        ▼
                                         ┌──────────────────────────┐
                                         │  accountHealthCard LWC   │
                                         │  @wire(getRecord)        │
                                         │  Reads Health_Rating__c  │
                                         │  Reads Last_Evaluated__c │
                                         │  Renders color badge     │
                                         └──────────────────────────┘
```

---

## File Locations

| Component | Path |
|-----------|------|
| Health Rating field metadata | `force-app/main/default/objects/Account/fields/Health_Rating__c.field-meta.xml` |
| Last Evaluated field metadata | `force-app/main/default/objects/Account/fields/Health_Rating_Last_Evaluated__c.field-meta.xml` |
| Trigger | `force-app/main/default/triggers/AccountTrigger.trigger` |
| Trigger metadata | `force-app/main/default/triggers/AccountTrigger.trigger-meta.xml` |
| Handler class | `force-app/main/default/classes/AccountTriggerHandler.cls` |
| Handler metadata | `force-app/main/default/classes/AccountTriggerHandler.cls-meta.xml` |
| Test class | `force-app/main/default/classes/AccountTriggerHandlerTest.cls` |
| Test metadata | `force-app/main/default/classes/AccountTriggerHandlerTest.cls-meta.xml` |
| LWC HTML template | `force-app/main/default/lwc/accountHealthCard/accountHealthCard.html` |
| LWC JavaScript controller | `force-app/main/default/lwc/accountHealthCard/accountHealthCard.js` |
| LWC CSS stylesheet | `force-app/main/default/lwc/accountHealthCard/accountHealthCard.css` |
| LWC metadata | `force-app/main/default/lwc/accountHealthCard/accountHealthCard.js-meta.xml` |

---

## Configuration Details

### Trigger Events

| Event | Handler Method | Purpose |
|-------|----------------|---------|
| `before insert` | `beforeInsert(List<Account>)` | Evaluates and stamps the health rating on new records before they are saved |
| `before update` | `beforeUpdate(List<Account>, Map<Id, Account>)` | Re-evaluates the health rating only when `AnnualRevenue` or `NumberOfEmployees` has changed |
| `after insert` | `afterInsert(List<Account>)` | No-op; present for completeness and future extension |
| `after update` | `afterUpdate(List<Account>, Map<Id, Account>)` | Detects At Risk transitions and creates Tasks |

### Task Created on At Risk Transition

A Task is created only when an Account transitions from a non-At-Risk rating to At Risk during an update. It is never created on insert.

| Task Field | Value |
|------------|-------|
| `Subject` | `Review At Risk Account: [Account Name]` |
| `WhatId` | The Account's Id |
| `OwnerId` | The Account Owner's Id |
| `Priority` | High |
| `Status` | Not Started |
| `ActivityDate` | Today + 3 days |

Tasks are collected in a list and inserted in a single DML call after the loop, making the handler fully bulk-safe.

### LWC — accountHealthCard

**Data source:** `@wire(getRecord)` from `lightning/uiRecordApi`. No Apex controller is involved.

**Wired fields:**
- `Account.Health_Rating__c`
- `Account.Health_Rating_Last_Evaluated__c`

**Badge colors:**

| Rating | CSS Class | Color |
|--------|-----------|-------|
| Good | `badge badge-good` | Green (`#2e844a`) |
| Average | `badge badge-average` | Orange (`#f59300`) |
| At Risk | `badge badge-at-risk` | Red (`#c23934`) |
| No rating / unknown | `badge badge-unknown` | Gray (`#706e6b`) |

Colors use SLDS CSS custom properties (`var(--lwc-colorTextSuccess)`, etc.) with hex fallbacks for environments where the design tokens are unavailable.

**Last Evaluated display:** Rendered using `<lightning-formatted-date-time>` with year (numeric), month (short), day (2-digit), hour (2-digit), and minute (2-digit). This produces output such as "May 12, 2026, 10:30 AM".

**Error handling:** If the wire adapter returns an error, a short error message ("Unable to load health rating.") is displayed in place of the badge. No edit or save functionality is included.

---

## Setup Instructions — Adding the LWC to the Account Record Page

The `accountHealthCard` component is exposed to the App Builder and restricted to Account Record Pages. To add it:

1. Navigate to any Account record in your Salesforce org.
2. Click the gear icon (Setup) in the top-right corner, then select **Edit Page**.
3. The Lightning App Builder opens. In the left-hand components panel, locate **accountHealthCard** under the Custom section (search for "Account Health" if needed).
4. Drag the component to the desired position on the page layout. Common placements are the right-hand sidebar or above the Activity timeline.
5. Click **Save**.
6. Click **Activate** if the page has not been activated before, or if you want the changes to take effect for all users. Choose the appropriate activation scope (org default, app default, or profile-specific).
7. Return to the Account record. The health badge will be visible immediately for accounts that have a `Health_Rating__c` value. Newly created or recently updated accounts will always have a rating, since the trigger sets it on every insert and on every relevant update.

**Note:** The component requires that the running user has read access to `Health_Rating__c` and `Health_Rating_Last_Evaluated__c` on the Account object. If the badge shows an error message, verify field-level security for the user's profile or permission set.

---

## Testing

### Test Coverage Summary

| Class | Coverage | Status |
|-------|----------|--------|
| `AccountTriggerHandler` | ~95%+ | Pass |
| `AccountTrigger` | ~95%+ | Pass |

### Test Methods

| Method | Scenario |
|--------|----------|
| `testBeforeInsert_goodRating` | Insert with revenue > $10M and employees > 500 → Health_Rating__c = 'Good', timestamp populated |
| `testBeforeInsert_atRiskRating_noTaskCreated` | Insert with revenue < $1M and employees < 100 → rating = 'At Risk', zero Tasks created |
| `testBeforeInsert_averageRating_nullValues` | Insert with null revenue and employees → rating = 'Average' |
| `testBeforeInsert_averageRating_midRangeValues` | Insert with mid-range values → rating = 'Average' |
| `testBeforeInsert_averageRating_partialGoodCondition` | Revenue meets Good threshold but employees does not → 'Average' |
| `testBeforeInsert_averageRating_partialAtRiskCondition` | Revenue meets At Risk threshold but employees does not → 'Average' |
| `testBeforeUpdate_unrelatedFieldChange_ratingNotReEvaluated` | Updating Phone only → rating unchanged (performance guard verified) |
| `testBeforeUpdate_revenueChange_transitionsToAtRisk_taskCreated` | Revenue + employees drop to At Risk thresholds → rating = 'At Risk', one Task created with correct Subject, Priority, Status, and due date |
| `testAfterUpdate_alreadyAtRisk_noAdditionalTaskCreated` | Already At Risk, updated revenue stays below threshold → zero additional Tasks |
| `testAfterUpdate_atRiskToGood_noTaskCreated` | Transition from At Risk to Good → zero Tasks |
| `testAfterUpdate_averageToAtRisk_taskCreated` | Transition from Average to At Risk → one Task created |
| `testBulkUpdate_200AccountsTransitionToAtRisk_200TasksCreated` | 200 accounts transition to At Risk in one DML call → exactly 200 Tasks, no governor limit violations |
| `testBeforeInsert_revenueAtGoodThreshold_isAverage` | Revenue = exactly $10,000,000 with employees > 500 → 'Average' (boundary: strictly greater than) |
| `testBeforeInsert_revenueAtAtRiskThreshold_isAverage` | Revenue = exactly $1,000,000 with employees < 100 → 'Average' (boundary: strictly less than) |

### Running Tests

To run the test class from the CLI:

```
sf apex run test --class-names AccountTriggerHandlerTest --result-format human --synchronous
```

---

## Security

### Sharing Model

- `AccountTriggerHandler` is declared `public with sharing`, so all record visibility is governed by the running user's sharing rules.
- Task inserts use `Database.insert(tasksToInsert, AccessLevel.USER_MODE)`, which enforces the running user's object and field permissions at the DML level.

### LWC Data Access

The LWC uses `@wire(getRecord)` from `lightning/uiRecordApi`, which automatically respects field-level security. If a user lacks read permission on `Health_Rating__c` or `Health_Rating_Last_Evaluated__c`, those field values will be absent from the wire response and the badge will display "Not evaluated".

### Required Permissions for End Users

Users who need to see the health badge on the Account Record Page must have:

- Read access to `Account.Health_Rating__c`
- Read access to `Account.Health_Rating_Last_Evaluated__c`

Users whose saves trigger Task creation (any user who updates Account revenue or headcount) will have Tasks created on their behalf because the trigger runs in the context of the running user; the Task owner is set to the Account's owner, not necessarily the user who triggered the save.

---

## Notes and Considerations

### Known Limitations

- **Health Rating on update is only re-evaluated when `AnnualRevenue` or `NumberOfEmployees` changes.** If an admin manually edits `Health_Rating__c` directly on the record (e.g., via the field editor), the trigger will not override the manual value unless one of the two source fields also changes in the same save operation.
- **No periodic re-evaluation.** Ratings are only updated on record save. An account whose revenue does not change will retain its existing rating indefinitely, even if business context changes externally. A scheduled Apex batch could be added in the future to re-evaluate all accounts on a schedule.
- **Task due date is hardcoded to today + 3 days.** This is not configurable via Custom Metadata or Custom Settings. If the business requires a different lead time, the constant must be updated in `AccountTriggerHandler.afterUpdate`.
- **The LWC has no edit capability.** It is a read-only display component. Users must edit the Account record directly to trigger a rating change.
- **API version is 59.0.** The `Database.insert` call uses `AccessLevel.USER_MODE`, which was introduced in API 57.0, so the minimum supported API version for this handler is 57.0.

### Future Enhancements

- Add a scheduled Apex batch job (`AccountHealthRatingBatch`) to re-evaluate all accounts nightly, ensuring ratings stay current without requiring a manual save.
- Move the threshold values ($10M, $1M, 500, 100) and the task due-date offset (3 days) into a Custom Metadata Type (`Account_Health_Config__mdt`) to make them configurable without code changes.
- Extend the LWC to display a trend indicator (e.g., a small arrow icon) showing whether the rating improved or worsened since the last evaluation, derived from a historical field or a related rating history object.
- Add an email notification or Chatter post when a Task is created for an At Risk transition, so account owners are alerted even when not actively monitoring Salesforce.
- Consider adding a Health_Rating_Previous__c field to track the prior rating, enabling reporting on how often accounts recover from At Risk to Good.

### Dependencies

| Dependency | Required By |
|------------|-------------|
| `Account.Health_Rating__c` | `AccountTriggerHandler`, `accountHealthCard` LWC |
| `Account.Health_Rating_Last_Evaluated__c` | `AccountTriggerHandler`, `accountHealthCard` LWC |
| `Account.AnnualRevenue` (standard) | `AccountTriggerHandler` — rating evaluation logic |
| `Account.NumberOfEmployees` (standard) | `AccountTriggerHandler` — rating evaluation logic |
| `Account.OwnerId` (standard) | `AccountTriggerHandler` — Task assignment |

The two custom fields must be deployed before the Apex classes and the LWC, as both reference `Health_Rating__c` by name.

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-05-12 | Documentation Agent | Initial creation |
