---
name: project-conventions
description: Key project-level conventions that affect how test classes are written in this repo
metadata:
  type: project
---

- API version: 59.0 (from sfdx-project.json sourceApiVersion)
- No namespace
- Package directory: force-app/main/default
- Test class location: force-app/main/default/classes/
- Naming convention: {ClassName}Test.cls
- No existing test classes existed in the project as of May 2026 (no patterns to mirror)
- Meta file format: apiVersion 59.0, status Active
- Database.insert with AccessLevel.USER_MODE is used in production code (API 59+ pattern)
- `with sharing` on all service/handler classes

**Why:** Project sfdx-project.json is the source of truth for API version; no test baseline existed when first test class was created.
**How to apply:** Always check sfdx-project.json before writing meta files; default to 59.0 if unchanged.
