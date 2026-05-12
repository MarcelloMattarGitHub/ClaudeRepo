---
name: deployment-lwc-internal-tokens
description: LWC deployments fail when CSS references internal SLDS design tokens like --lwc-colorTextSuccess/Warning/Error from the 'c' namespace
metadata:
  type: feedback
---

LWC CSS in the `c` (custom) namespace cannot reference SLDS internal design tokens such as `--lwc-colorTextSuccess`, `--lwc-colorTextWarning`, `--lwc-colorTextError`. Deployment fails with: `Access to TOKEN 'force:base.colorTextSuccess' with access 'INTERNAL' is not allowed from namespace 'c'`.

**Why:** These tokens have `INTERNAL` access modifier and are reserved for Salesforce's own first-party LWCs. Custom-namespace components must use either hex literals, public SLDS Design Tokens, or SLDS styling hooks (e.g. `--slds-g-color-success-base-50`).

**How to apply:** Before deploying any LWC, scan the bundle's `.css` files for `var(--lwc-color*)` patterns or any `--lwc-*` token. If found, do not deploy — return the file/line to the developer agent for replacement with hex literals or public styling hooks. The deployment will fully roll back on this error, so other components in the same deploy are NOT created.
