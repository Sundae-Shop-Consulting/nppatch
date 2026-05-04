# PR Review Guide

This file captures repo-specific gotchas and review heuristics for AI-driven PR reviews of this Salesforce DX / CumulusCI project. It is meant to be loaded into context when reviewing PRs.

If you learn a new gotcha during a review that future reviewers should know, add it here.

---

## PR Description Format (REQUIRED)

CumulusCI's release notes parser requires **H1 headings**. PRs without these headings appear under "Pull requests with no release notes."

- `# Changes` — main section listing what changed (REQUIRED)
- `# Critical Changes` — breaking changes
- `# Issues Closed` — linked issues

**Flag**: PRs that use `## Summary`, `## Changes`, or other H2-as-primary structure. The template lives at `.github/PULL_REQUEST_TEMPLATE.md`.

---

## Repo Layout Reference

| Path | What it is |
|------|------------|
| `force-app/nppatch-main/default/` | Main package source (NOT `force-app/main/default/`) |
| `force-app-common/infrastructure/` | Common package (fflib: apex-common, apex-extensions, apex-mocks) |
| `force-app/bdi/default/` | BDI-isolated source directory |
| `force-app/nppatch-pmm/default/` | PMM source (feature/pmm branch) |
| `unpackaged/pre/` | MDAPI bundles deployed before the package |
| `unpackaged/post/` | MDAPI bundles deployed after the package |
| `unpackaged/config/` | Per-flow MDAPI config (dev, demo, all_record_types, delete) |

Namespace: `nppatch`. Multi-package: `nppatch-common` (Common) → `nppatch` (main), both share the `nppatch` namespace.

---

## Format Split (Critical)

- **`force-app/` uses SFDX source format** — decomposed (`Foo/fields/Bar.field-meta.xml`)
- **`unpackaged/` uses MDAPI format** — single-file (`Foo.object` with everything inline)

**Flag**: any mixing of the two formats within the same directory tree.

---

## Reviewing `unpackaged/` Metadata

### `.object` files in `unpackaged/post/` should be deltas, not full schemas

A common anti-pattern is `sf project retrieve` dumps committed wholesale. Symptoms:
- Default action overrides for every standard action (`Accept`, `CancelEdit`, `Clone`, `Delete`, `Edit`, `List`, `New`, `SaveEdit`, `Tab`, `View`) with `<type>Default</type>`, often with `Large` and `Small` formFactor variants
- Full field definitions for fields that already exist in `force-app/` (especially MD relationships — easy to mistake for new schema)
- `<searchLayouts>`, `<compactLayouts>`, `<listViews>` that duplicate packaged source

**Flag**: any duplication. Compare against `force-app/nppatch-main/default/objects/<Object>/` to identify what's actually new.

### Watch for silent setting overrides

These top-level CustomObject elements become the source of truth post-install:
- `<enableFeeds>`
- `<enableActivities>`
- `<enableHistory>`
- `<sharingModel>` / `<externalSharingModel>`
- `<visibility>`

**Flag**: any value that differs from the packaged equivalent. Ask whether the change is intentional. Most retrievals ship unintentional drift.

### MDAPI partial CustomObject deploy requirements

If a PR slims an `.object` file to just deltas, **custom objects** still need this minimum identity block or the deploy fails (errors come one at a time):
- `<label>`
- `<pluralLabel>`
- `<nameField>` (with `displayFormat`/`type` matching packaged)
- `<deploymentStatus>Deployed</deploymentStatus>`
- `<sharingModel>` (+ `<visibility>Public</visibility>` if packaged has it)
- `<enableActivities>true</enableActivities>` when any bundled layout references activity-related lists (`RelatedActivityList`, `RelatedHistoryList`, `TASK.*`, `ACTIVITY.*`)

**Standard objects (e.g., Opportunity) are exempt.** Copy required values verbatim from the packaged `.object-meta.xml` to avoid silent overwrites.

### Flexipage assignment requires CustomObject action overrides

There is no profile- or app-level metadata equivalent for Flexipages. Profile `layoutAssignments` work only for classic page layouts.

To assign a Lightning record page from MDAPI, the bundle MUST include a CustomObject with `actionOverrides` of `<type>Flexipage</type>` for `View` (typically `Large` and `Small` formFactor). Manual UI assignment in Lightning App Builder is the only alternative.

---

## Field / Object Deletion Ripple

When a PR deletes custom fields or objects, verify these metadata types are also cleaned up:

- **Layouts** — reference fields directly
- **Profiles** — `<fieldPermissions>`, `<layoutAssignments>`
- **Permission sets** — `<fieldPermissions>` etc. Use `%%%NAMESPACE%%%` tokens (in `*.permissionset-meta.xml`)
- **Object translations** — decomposed format; each field translation is its own `.fieldTranslation-meta.xml`
- **`<apex:include>`** in VF pages — references pages by name, fails if target deleted
- **`<aura:dependency>`** in Aura components — same
- **`@salesforce/schema` imports** in LWC — compile-time checked. If field metadata is deleted, convert to `const X = { fieldApiName: '...', objectApiName: '...' }` to preserve the shape for `apiNameFor()` calls.

**Note**: Profile XML does NOT use `%%%NAMESPACE%%%` tokens; permission set XML DOES. Don't add tokens to profiles.

**Note**: `__tests__/` directories per LWC component contain Jest tests and are NOT deployed — references there don't block deployment.

---

## LWC Review Heuristics

### Namespace handling for LWC↔Apex (DO NOT manually prefix)

- The Lightning framework auto-resolves `nppatch__` for same-namespace LWC↔Apex calls
- Apex `@AuraEnabled` returns field names **WITHOUT** namespace prefix (e.g., `Formal_Greeting__c`, not `nppatch__Formal_Greeting__c`)
- Sending data **WITH** manual prefix causes field values to be **SILENTLY LOST** during deserialization
- Only strip internal LWC keys (`_key`, `dtNewContact`) before sending to Apex — use the `_stripInternalKeys()` pattern
- `_removePrefix` on incoming data is harmless (no-op if data already unprefixed)
- `getChildObjectByName` from `c/util` checks both prefixed and unprefixed — safe for reading
- `sobjectType` for custom objects should also be unprefixed (e.g., `"Address__c"`, not `"nppatch__Address__c"`)

**Flag**: any code that manually adds or strips the `nppatch__` prefix on field names sent to Apex.

### Navigation patterns

- **LWC RecordAction quick actions cause navigation loops** — use URL custom buttons instead
- See `feedback_lwc_quick_actions_navigation.md` and `feedback_lwc_navigation_patterns.md` in user memory for detail

### FlexiPages

- Component references: use **bare component name** (e.g., `nppatchSettings`), NOT namespace-prefixed
- FlexiPages at API 63.0 require `<identifier>` inside every `<componentInstance>` block — convention: component name with colons→underscores (e.g., `force:detailPanel` → `force_detailPanel`). Numeric suffix for duplicates on same page.

---

## Apex Review Heuristics

- **Case-sensitive field refs**: e.g., `Payment_Elevate_Id__c` vs `Payment_Elevate_ID__c`. Use case-insensitive grep (`-i`) when scanning for field references.
- **Metadata API compiles ALL Apex together** — one class with a missing dependency causes ALL classes to fail, which then cascades into VF page errors. When reviewing changes that delete or rename Apex classes, verify nothing else still references them.
- **CCI namespace tokens** in AnonymousApexTask: `%%%NAMESPACE%%%` and `%%%NAMESPACED_RT%%%` follow specific unlocked-package visibility rules. See `feedback_cci_namespace_tokens.md` in user memory.

---

## CumulusCI / Build Configuration

- `cci flow run dev_org` — full deployment to scratch org
- `cci deploy_unmanaged` only deploys `force-app` (hardcoded `path: force-app` for SFDX scratch orgs). Additional package directories need explicit `deploy` steps added via flow override.
- **CCI step numbers are `major.minor` with integer minor** — `3.05` = minor 5 (sorts AFTER `3.1` = minor 1). To insert before `3.1`, use `2.9`.
- **Duplicate CustomLabel `<fullName>` values** across source directories cause deploy errors — flag any new label that already exists elsewhere.
- **Top-level `lwc/__tests__/`** directories get treated as LWC components by Metadata API and break deploys. Per-component `__tests__/` directories inside individual LWC folders are fine.

---

## What NOT to Do During Review

- Don't run `cci flow run dev_org` or `cci flow run release_unlocked_beta` without explicit permission
- Don't run long-running deployment or package commands automatically
- Don't push to git without explicit permission
- Don't approve a PR without checking the deployment story (will it deploy clean? does it break the next release flow?)

---

## Standard Review Checklist

For every PR, walk through:

1. **Description format** — H1 headings present?
2. **Scope match** — does the diff match what the description claims?
3. **Format consistency** — is `unpackaged/` MDAPI and `force-app/` SFDX, with no mixing?
4. **Unpackaged metadata** — are `.object` files deltas or `retrieve` dumps? Any silent setting overrides?
5. **Deletion ripple** — if fields/objects/classes were deleted, are all referencing types cleaned up?
6. **Namespace handling** — any manual `nppatch__` prefixing in LWC↔Apex code?
7. **Apex compilation** — does the change reference anything that's also being deleted?
8. **CCI flows** — does any new metadata directory need explicit `deploy` steps in the flow?
9. **Tests** — Jest tests for LWC changes, Apex tests for Apex changes
10. **Documentation** — README/docs updated when behavior changes
