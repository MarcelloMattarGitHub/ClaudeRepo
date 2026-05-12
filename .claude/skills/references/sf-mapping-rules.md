# Salesforce Component Mapping Rules

These rules encode Salesforce implementation best practices for mapping business requirements to platform components. Claude MUST use these rules when analyzing requirements — do NOT rely on general knowledge.

## Component Selection Matrix

### When to use Configuration (Declarative)
Use when the requirement involves:
- **New data capture**: Custom Object, Custom Field, Record Type, Page Layout
- **Data validation**: Validation Rule, Required Field, Unique Field
- **Simple automation trigger**: Field Update, Email Alert
- **Picklist/dropdown values**: Picklist Field, Global Value Set, Dependent Picklist
- **Simple page customization**: Page Layout, Compact Layout, Lightning App Page

**Keywords that signal Configuration**: "store", "capture", "track", "record", "field", "dropdown", "picklist", "required", "unique", "category", "type", "status"

### When to use Flow
Use when the requirement involves:
- **User-facing process**: Screen Flow (wizard, guided process, form)
- **Automation on record change**: Record-Triggered Flow (before-save for field defaults, after-save for cross-object updates)
- **Scheduled automation**: Scheduled Flow (nightly jobs, recurring tasks)
- **Approval routing**: Flow-based Approval Process
- **Email/notification**: Autolaunched Flow with Email Action

**Keywords that signal Flow**: "when...then", "automatically", "notify", "approval", "route", "assign", "escalate", "schedule", "wizard", "guide", "step-by-step", "if...then", "workflow"

### When to use Apex
Use when the requirement involves:
- **Complex business logic**: Apex Trigger + Handler (multi-object transactions, rollup calculations, complex validations beyond formula limits)
- **Bulk data processing**: Batch Apex (data cleanup, mass updates, data migration)
- **Async processing**: Queueable Apex (callouts, chained operations)
- **External API integration**: Apex REST/SOAP (inbound/outbound integrations)
- **Custom web service**: Apex REST Service (expose Salesforce data to external systems)

**Keywords that signal Apex**: "complex calculation", "bulk", "batch", "integrate with", "API", "external system", "real-time sync", "rollup", "aggregate across", "transaction", "callout"

### When to use LWC
Use when the requirement involves:
- **Custom UI beyond standard layouts**: Lightning Web Component
- **Interactive data visualization**: LWC with chart library
- **Custom search/filter experience**: LWC with wire service
- **Override standard buttons/actions**: LWC Quick Action, Record Page Override
- **Embedded component**: LWC in Flow Screen, LWC in App Page

**Keywords that signal LWC**: "custom screen", "dashboard widget", "interactive", "drag and drop", "custom search", "visual", "real-time update", "override", "custom button", "UI"

### When to use Integration
Use when the requirement involves:
- **External system data sync**: REST/SOAP Integration (Apex + Named Credential)
- **Real-time event-driven**: Platform Events (for internal) or CDC (for external)
- **Middleware/ETL**: MuleSoft, Informatica, or Middleware pattern
- **File exchange**: Batch file integration (CSV/XML import/export)
- **SSO/Authentication**: OAuth, SAML, External Client App

**Keywords that signal Integration**: "sync with", "integrate", "external system", "SAP", "ERP", "third-party", "data feed", "import", "export", "middleware", "real-time data", "webhook"

### When to use Security
Use when the requirement involves:
- **Role-based access**: Profile, Permission Set, Permission Set Group
- **Record-level access**: OWD, Sharing Rules, Manual Sharing, Apex Sharing
- **Field-level security**: FLS on Permission Set
- **Data visibility**: Sharing Sets (Community/Portal)

**Keywords that signal Security**: "access", "permission", "role", "visibility", "restrict", "only managers can", "confidential", "view only", "edit access", "who can see"

### When to use Reporting
Use when the requirement involves:
- **Standard reports**: Report, Report Type, Report Folder
- **Visual analytics**: Dashboard, Dashboard Component
- **Cross-object reporting**: Custom Report Type, Joined Reports
- **Real-time metrics**: Dynamic Dashboard, Dashboard Filter

**Keywords that signal Reporting**: "report", "dashboard", "KPI", "metrics", "analytics", "chart", "trend", "measure", "track performance", "weekly report", "summary"

---

## Complexity Estimation Rules

### Simple (1-2 Story Points)
- Single field addition to existing object
- Validation rule (single condition)
- Simple page layout change
- Standard report or list view
- Picklist value addition
- Permission set field-level security update
- Simple email template

### Medium (3-5 Story Points)
- Custom object with 5-10 fields and 1-2 relationships
- Record-triggered flow (single object, 2-3 decisions)
- Screen flow (3-5 screens, no external data)
- Lightning App Page customization
- Custom report type with 2-3 objects
- Dashboard with 5-8 components
- Validation rule with cross-object formula
- Approval process (2 levels)

### Complex (8-13 Story Points)
- Apex trigger with handler pattern (multi-object, bulk-safe)
- LWC with Apex controller and wire service
- Record-triggered flow (cross-object, 5+ decisions, DML on 3+ objects)
- Batch Apex job with error handling and logging
- Integration with single external system (REST API)
- Complex sharing model (OWD + Sharing Rules + Apex Sharing)
- Data migration (single object, 50K+ records)
- Screen flow with external data lookup and conditional branching

### Epic (13+ Story Points — break into sub-stories)
- Multi-system integration (2+ external systems)
- Full data migration (multiple objects, data transformation, validation)
- Complex LWC application (multi-component, state management, real-time)
- Enterprise security model (multiple profiles, sharing rules, territory management)
- Custom community/portal with authentication and record access
- Reporting suite (10+ reports, 3+ dashboards, custom report types)

---

## Acceptance Criteria Templates

### For Configuration
```
Given a user with {profile/permission_set} access,
When they navigate to {object} and create/edit a record,
Then the {field_name} field should {behavior}.
And the page layout should display {sections/fields} based on {record_type}.
```

### For Flows
```
Given a {trigger_event} on {object} where {entry_conditions},
When the flow executes,
Then {expected_outcome_1},
And {expected_outcome_2},
And the user should {receive_notification/see_screen/etc}.
Error handling: If {error_condition}, then {fallback_behavior}.
```

### For Apex
```
Given {precondition},
When {trigger_event} occurs on {object} for {single_and_bulk} records,
Then the system should {expected_behavior},
And all DML operations should be bulkified (200+ records),
And errors should be logged to {Custom_Object/Platform_Event},
And governor limits should not be exceeded.
Unit test coverage: minimum 90% with positive, negative, and bulk scenarios.
```

### For LWC
```
Given a user on the {page_type} page for {object},
When they interact with the {component_name} component,
Then {expected_UI_behavior},
And data should refresh without full page reload,
And the component should handle loading, error, and empty states,
And be accessible (WCAG 2.1 AA compliant).
```

### For Integration
```
Given {source_system} has {new/updated} data,
When the integration runs {frequency},
Then {target_system} should receive {data_description},
And field mapping should follow: {field_map},
And failed records should be logged with retry mechanism,
And the integration should handle {volume} records per {timeframe}.
Authentication: {Named_Credential/OAuth/Certificate}.
```

### For Security
```
Given a user with {role/profile},
When they access {object/record},
Then they should {see/not_see} records where {sharing_condition},
And they should be able to {create/read/edit/delete} based on {permission_level},
And field-level security should hide {restricted_fields} from {profiles}.
```

---

## Sprint Grouping Logic

### Sprint 1 — Foundation (Data Model)
- Custom objects and fields
- Record types and page layouts
- Relationships (Lookup, Master-Detail)
- Picklist values and Global Value Sets

### Sprint 2 — Security & Access
- Profiles and Permission Sets
- OWD and Sharing Rules
- FLS configuration
- Role Hierarchy (if needed)

### Sprint 3 — Automation
- Validation Rules
- Record-Triggered Flows
- Scheduled Flows
- Approval Processes
- Apex Triggers (if any)

### Sprint 4 — User Interface
- Lightning App Pages
- Screen Flows
- LWC Components
- Quick Actions
- Page Layout refinements

### Sprint 5 — Integration
- Named Credentials
- Apex REST/SOAP services
- Platform Events
- Middleware configuration
- Data Migration

### Sprint 6 — Reporting & Go-Live Prep
- Reports and Report Types
- Dashboards
- User training materials
- UAT test scripts
- Data validation
