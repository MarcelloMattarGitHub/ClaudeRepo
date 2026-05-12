═══════════════════════════════════════════════════════════════════════════════
                    DESIGN REQUIREMENTS
       Feature: Soft Drink Order — Expired / Insufficient Stock Validation
═══════════════════════════════════════════════════════════════════════════════

WHAT USER REQUESTED:
Create a validation rule on Soft_Drink_Order__c that prevents saving an order when:
- The related Soft Drink's Status is 'Expired', OR
- The Quantity ordered is greater than the Soft Drink's Quantity Left.

Formula (approved by user):
    OR(
      Soft_Drink__r.Status__c = 'Expired',
      Quantity__c > Soft_Drink__r.Quantity_Left__c
    )

Error message (approved by user):
    "Cannot save this order: the Soft Drink is either Expired or does not have
     enough stock to fulfill the requested quantity."

───────────────────────────────────────────────────────────────────────────────
                    ADMIN WORK (salesforce-admin)
───────────────────────────────────────────────────────────────────────────────

1. Validation Rule on Soft_Drink_Order__c
   - Rule API Name: Prevent_Expired_Or_Insufficient_Stock
   - Active: true
   - Error Condition Formula:
         OR(
           Soft_Drink__r.Status__c = 'Expired',
           Quantity__c > Soft_Drink__r.Quantity_Left__c
         )
   - Error Message: "Cannot save this order: the Soft Drink is either Expired
     or does not have enough stock to fulfill the requested quantity."
   - Error Location: top of page (no specific errorDisplayField — user did not
     specify a field to attach the error to)

───────────────────────────────────────────────────────────────────────────────
                    DEVELOPMENT WORK (salesforce-developer)
───────────────────────────────────────────────────────────────────────────────

No development work required for this request. This is purely declarative.

───────────────────────────────────────────────────────────────────────────────
                    EXECUTION ORDER
───────────────────────────────────────────────────────────────────────────────

Single admin task — no dependencies. No execution-order concerns.

───────────────────────────────────────────────────────────────────────────────
                    CONTEXT (verified during analysis)
───────────────────────────────────────────────────────────────────────────────

- API Version: 59.0 (from sfdx-project.json — overrides the 65.0 mentioned in
  CLAUDE.md; the project's actual sourceApiVersion is the source of truth).
- Package Directory: force-app/main/default
- Soft_Drink_Order__c exists at:
      force-app/main/default/objects/Soft_Drink_Order__c/
- Soft_Drink_Order__c.Soft_Drink__c is a Master-Detail to Soft_Drink__c
  (verified in the field metadata).
- Soft_Drink_Order__c.Quantity__c exists (verified).
- Soft_Drink__c.Status__c is a restricted picklist with values "Safe to Use"
  and "Expired" (verified).
- Soft_Drink__c.Quantity_Left__c exists (verified — referenced by the formula).
- No existing validationRules folder under Soft_Drink_Order__c — the admin
  agent will create:
      force-app/main/default/objects/Soft_Drink_Order__c/validationRules/
          Prevent_Expired_Or_Insufficient_Stock.validationRule-meta.xml

───────────────────────────────────────────────────────────────────────────────
                    PROMPTS FOR SPECIALIST AGENTS
───────────────────────────────────────────────────────────────────────────────

PROMPT FOR salesforce-admin:
"""
Create a Validation Rule on the Soft_Drink_Order__c custom object. Generate the
metadata file only — do not deploy.

Project conventions:
- API Version: 59.0 (per sfdx-project.json)
- Package directory: force-app/main/default
- Standard ValidationRule metadata XML format with
  xmlns="http://soap.sforce.com/2006/04/metadata"

Specifications:
- Object: Soft_Drink_Order__c
- Validation Rule API Name (fullName): Prevent_Expired_Or_Insufficient_Stock
- active: true
- errorConditionFormula:
      OR(
        Soft_Drink__r.Status__c = 'Expired',
        Quantity__c > Soft_Drink__r.Quantity_Left__c
      )
- errorMessage: Cannot save this order: the Soft Drink is either Expired or does not have enough stock to fulfill the requested quantity.
- Do NOT set errorDisplayField (error should appear at the top of the page).

File to create:
    force-app/main/default/objects/Soft_Drink_Order__c/validationRules/Prevent_Expired_Or_Insufficient_Stock.validationRule-meta.xml

Do not:
- Add any additional fields, picklist values, layouts, permission sets, or
  other components.
- Modify any other existing files.
- Deploy the metadata. Deployment is handled by the salesforce-devops agent
  later in the workflow.
"""

PROMPT FOR salesforce-developer:
"""
No development work required for this request.
"""

═══════════════════════════════════════════════════════════════════════════════
