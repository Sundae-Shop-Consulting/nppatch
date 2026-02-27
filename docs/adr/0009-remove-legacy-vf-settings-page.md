# ADR-0009: Remove Legacy Visualforce Settings Page

**Status:** Accepted
**Date:** 2026-02-26

## Context

NPSP's settings management was built on a monolithic Visualforce architecture:

1. **`STG_SettingsManager.page`** — a single VF page that used jQuery tab navigation and `<apex:include>` to embed 36 panel pages
2. **`STG_SettingsManager_CTRL`** — a controller that ran initialization logic (`onNpspSettingsLoad()`) on every page load, including TDTM trigger handler setup and scheduled job configuration
3. **36 `STG_Panel*.page` files** — individual VF panel pages for each settings section
4. **25+ `STG_Panel*_CTRL` classes** — Apex controllers for each panel, extending `STG_Panel` base class

PR #62 and prior work built a complete LWC replacement:

- **`nppatchSettings`** — parent LWC with vertical navigation and conditional panel rendering
- **34 `stgPanel*` LWC components** — individual panels using `@wire(getSettings)` and `saveSettings` patterns
- **`NppatchSettingsController`** — shared Apex controller with generic `getSettings`/`saveSettings` for hierarchy Custom Settings and `getListSettings`/`saveListSettings` for list Custom Settings

With all 34 panels migrated and verified, the old VF infrastructure was dead code.

### Why remove now

- **~9,400 lines of dead code** across 142 files (36 VF pages, 25 controllers, 10 test classes, plus meta files)
- **`STG_SettingsManager_CTRL.onNpspSettingsLoad()`** ran TDTM initialization and job scheduling on every page load, making the old settings page slow (~5-10s cold start)
- **Cross-references created fragile coupling** — `STG_Panel.saveSettings()`, `editSettings()`, and `cancelEdit()` all wrote to `STG_SettingsManager_CTRL.idPanelCurrent`, and panel controllers directly referenced the manager
- **`Page.STG_SettingsManager` compile-time references** in unrelated classes (error tests, rollup UI, payment wizard) would break if only the VF page was deleted

## Decision

### Phase 1: Extract and decouple shared code

Before deleting anything, extract code that was embedded in controllers but needed elsewhere:

1. **Extract `OPP_AttributionSettings`** from `STG_PanelOppNaming_CTRL` — this class provides attribution setting options used by `OPP_OpportunityNaming`. It was embedded in the VF controller but is a domain concern.

2. **Move `getInvalidOCRSettings()`** from `STG_PanelContactRoles_CTRL` into `STG_PanelHealthCheck_CTRL` — this validation method is called by Health Check but lived in the deleted controller.

3. **Decouple `STG_Panel` from `STG_SettingsManager_CTRL`** — remove the three `idPanelCurrent` assignments from `saveSettings()`, `editSettings()`, and `cancelEdit()`. Remove `idPanelCurrent` references from all 5 kept controllers.

### Phase 2: Add initialization capability to LWC

The old VF page's `onNpspSettingsLoad()` ran on every load. Rather than replicate this slow behavior:

1. **Add `runInitialization()`** to `NppatchSettingsController` — calls `STG_InstallScript().runNewOrgScript()` and reschedules jobs. Exposed as a manual button ("Reinitialize TDTM & Scheduled Jobs") on the Health Check panel.

2. **Add `ensureSettingsExist(List<String>)`** — ensures org-level Custom Settings records exist before `@wire` calls. Uses a switch statement to call only the facade methods for specified settings objects, avoiding DML-in-cacheable-wire errors.

3. **Lazy loading pattern** — on page load, only ensure settings for the active panel (1 call). After the page renders, preload remaining settings in the background. Track ensured settings in a `Set` to avoid redundant calls on panel switch.

### Phase 3: Delete legacy files

1. **Delete 36 VF pages** + 36 meta files (72 files)
2. **Delete 25 panel controllers** + 25 meta files (50 files) — keeping only controllers with `verify()` methods used by Health Check: `STG_PanelHealthCheck_CTRL`, `STG_PanelADDRVerification_CTRL`, `STG_PanelPaymentMapping_CTRL`, `STG_PanelRelAuto_CTRL`, `STG_PanelRelReciprocal_CTRL`, `STG_PanelOppRollups_CTRL`, `STG_PanelOpps_CTRL`, `STG_PanelERR_CTRL`
3. **Delete 10 test classes** + 10 meta files (20 files) — tests for deleted controllers
4. **Delete `STG_SettingsManager_CTRL`** and `STG_SettingsManager_TEST` (1,458 lines)

### Phase 4: Fix broken references

Update all remaining compile-time references to deleted artifacts:

- **`ERR_Handler_TEST`** (4 occurrences) — `Page.STG_SettingsManager` → `new PageReference('/')`
- **`CRLP_RollupUI_SVC`** — `Page.STG_SettingsManager` → `Page.CRLP_RollupSetup` (used for namespace URL extraction)
- **`PMT_PaymentWizard.page`** — `$Page.STG_SettingsManager` link → `/lightning/n/NPPatch_Settings`
- **`contactsSettings.page`** and **`PaymentMapping.page`** — redirect to `/lightning/n/NPPatch_Settings`
- **`OPP_OpportunityNaming_TEST`** — `STG_PanelOppNamingBatch_CTRL` → `Database.executeBatch(new OPP_OpportunityNaming_BATCH(), 200)`
- **`STG_UninstallScript_TEST`** — `STG_SettingsManager_CTRL` → `UTIL_MasterSchedulableHelper.setScheduledJobs()`

### UX improvements

- **Default panel**: Account Model (first in nav list) instead of Membership
- **Centered loading spinners**: replaced `slds-is-relative` with flex-centered `.loading-container` across all 29 panel components
- **Status Automation layout**: rewrote `rd2StatusAutomationSettings` from horizontal `lightning-layout` to vertical `setting-row` pattern with shadow DOM CSS

### What we kept

- **`STG_Panel.cls`** — base class still used by kept controllers for Health Check verification
- **`STG_SettingsService.cls`** — provides settings service used by other features
- **8 panel controllers** with `verify()` methods — called by `STG_PanelHealthCheck_CTRL` to validate configuration
- **`RD2_StatusMappingSettings_CTRL`** and **`RD2_StatusAutomationSettings_CTRL`** — dedicated controllers for RD2 components

## Consequences

### Positive

- **~9,400 lines deleted** across 142 files — significant reduction in dead code
- **Faster settings page** — LWC loads in <1s vs 5-10s for the old VF page. Lazy settings initialization means only one Custom Settings object is ensured on initial load.
- **No more per-pageload initialization** — TDTM setup and job scheduling moved to a manual button, eliminating unnecessary DML on every settings page visit
- **Cleaner architecture** — `NppatchSettingsController` provides a generic `getSettings`/`saveSettings` pattern instead of 25 purpose-built controllers
- **Fewer cascading compile failures** — removed `Page.STG_SettingsManager` references that created fragile cross-dependencies

### Negative

- **Old VF settings URL is dead** — any bookmarks or hardcoded links to `STG_SettingsManager` will 404. Mitigated by updating the three remaining VF pages that linked to it.
- **TDTM/scheduled jobs no longer auto-initialize** — admins must click "Reinitialize" on the Health Check panel if trigger handlers or jobs get into a bad state. In practice, `STG_InstallScript` already runs during package install, so this is only needed for manual recovery.
- **8 legacy controllers retained** — these can't be deleted until Health Check verification methods are refactored into the LWC architecture (future work).

## References

- PR #64: Remove legacy VF settings page, complete LWC migration
- PR #62: Add revised settings page and components
- [ADR-0008](0008-remove-legacy-bge-and-always-enable-gift-entry.md): Remove Legacy BGE (similar pattern)
- [ADR-0006](0006-removed-salesforce-specific-functionality.md): Removed Salesforce-specific functionality
