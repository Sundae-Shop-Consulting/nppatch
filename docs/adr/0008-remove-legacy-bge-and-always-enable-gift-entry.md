# ADR-0008: Remove Legacy Batch Gift Entry (BGE) and Make Gift Entry Always-On

**Status:** Accepted
**Date:** 2026-02-24

## Context

NPSP shipped two generations of its batch gift entry UI:

1. **Legacy Batch Gift Entry (BGE)** — an Aura-based UI (`BGE_*` classes and components) that allowed admins to configure batch templates, enter gifts in a spreadsheet-like interface, and run BDI dry runs. It included a configuration wizard, donation selector, and entry form.
2. **Modern Gift Entry (GE)** — a Lightning Web Component-based replacement (`GE_*`, `ge*` components) with a template builder, improved UX, and tighter integration with the BDI Advanced Mapping engine.

The two UIs coexisted behind feature flags:

- **Gift Entry enablement**: `Gift_Entry_Settings__c` controlled whether modern Gift Entry was available. `GiftEntryEnablementService.isEnabled()` gated access, and a toggle in NPSP Settings allowed admins to enable/disable it.
- **Advanced Mapping**: A prerequisite for modern Gift Entry; handled separately (made always-on in PR #58).

PR #58 (Phase 1) made Advanced Mapping always-on, removed Help Text mapping, and deleted legacy BDI migration code. This PR completes Phase 2.

### Why remove now

NPPatch is a greenfield fork with no production installs running the legacy BGE UI. Keeping both UIs:

- Maintains ~6,000 lines of dead Apex/Aura code (8 classes, 5 component bundles) that duplicates functionality in the modern GE components
- Requires a manual enablement step that provides no value for new installs
- Leaves confusing toggle UI in the settings panel
- Increases package size and test execution time

## Decision

### Delete all legacy BGE components

1. **Delete 8 BGE Apex classes** and their tests:
   - `BGE_BatchGiftEntryTab_CTRL` — legacy tab container controller
   - `BGE_BatchGiftEntry_UTIL` — shared utility methods for legacy BGE
   - `BGE_ConfigurationWizard_CTRL` — legacy batch configuration wizard
   - `BGE_DataImportBatchEntry_CTRL` — legacy batch entry form controller

2. **Delete 5 BGE Aura component bundles:**
   - `BGE_BatchGiftEntryTab` — tab container
   - `BGE_ConfigurationWizard` — batch setup wizard
   - `BGE_DataImportBatchEntry` — main entry form
   - `BGE_DonationSelector` — donation matching UI
   - `BGE_EntryForm` — individual gift entry form

3. **Delete `Batch_Gift_Entry` custom tab** and `BatchGiftEntryTabColumns` field set

4. **Delete 59 `bge*` custom labels** and their translations across 8 languages

### Migrate `runBatchDryRun` before deleting

The modern Gift Entry LWC `geGiftBatch.js` imported `runBatchDryRun` from `BGE_DataImportBatchEntry_CTRL`. Before deletion:

1. **Migrated `runBatchDryRun`** and supporting helper methods to `GE_GiftEntryController`
2. **Simplified dependencies**: replaced `BGE_BatchGiftEntry_UTIL.getDataImportFields()` with `BDI_DataImportService.strSoqlForBatchProcess()` and removed the `checkFieldPermissions()` call that depended on the deleted utility class
3. **Created new inner classes** `DryRunDataImportModel` and `DryRunDataImportRow` in `GE_GiftEntryController` to replace the ones from the deleted controller
4. **Updated the LWC import** in `geGiftBatch.js` to point to `GE_GiftEntryController.runBatchDryRun`

### Make Gift Entry always-on

Following the same pattern as Advanced Mapping (PR #58):

1. **`GiftEntryEnablementService.isEnabled()`** → hardcoded to return `true`
2. **`GiftEntryEnablementService.enable()`** → no-op for backward compatibility
3. **`GE_Template.giftEntryIsEnabled()`** → hardcoded to return `true`
4. **`GE_SettingsService.isRecurringGiftsEnabled()`** → removed the `isEnabled()` gate, now only checks field accessibility
5. **`Callable_API` `settings.enablegiftentry` action** → no-op (matching `settings.enableadvancedmapping` pattern)
6. **`utilTemplateBuilder.js` `getPageAccess()`** → removed `GIFT_ENTRY_FEATURE_GATE` check

### Remove the settings toggle

1. **Removed from `STG_PanelDataImportAdvancedMapping_CTRL`**: `isGiftEntryEnabled` property, `enableGiftEntry()` method, `disableGiftEntry()` method
2. **Removed from VF page**: Gift Entry toggle section, action functions, and JavaScript. Kept the "Go to Setup" button and `bdiBatchNumberSettings` component.

### What we kept

- **`BGE_FormTemplate_TDTM`** — despite the `BGE_` prefix, this trigger handler prevents deletion of `Form_Template__c` records used by active Gift Entry batches. It's needed by modern Gift Entry.
- **`Batch_Gift_Entry_Version__c` field** — still referenced by `geBatchWizard.js` and `utilTemplateBuilder.js` to track batch template versions
- **11 `bge*` custom labels** — still referenced by modern GE LWC components (`bgeActionDelete`, `bgeActionView`, `bgeBatchDryRun`, `bgeEditPaymentInformation`, `bgeGridGiftDeleted`, `bgeGridGiftSaved`, `bgeGridNoGiftsBody`, `bgeGridNoGiftsHeader`, `bgeProcessBatch`, `bgeProcessBatchAndPayments`, `bgeTabHeader`)

## Consequences

### Positive

- **~9,700 lines deleted** across 76 files — removes dead UI code, labels, and translations
- **Gift Entry works out of the box** — no manual enablement step required for new installs
- **Simpler settings panel** — no toggle UI, just the "Go to Setup" button for Advanced Mapping configuration
- **Single code path** for batch gift entry — no branching between legacy and modern UIs
- **Faster CI** — fewer classes to compile and test

### Negative

- **No legacy BGE fallback** — if a bug is found in the modern Gift Entry UI, the legacy UI is gone. This is acceptable because the modern GE is mature and NPPatch has no production data at risk.
- **`runBatchDryRun` method moved** — any external code calling `BGE_DataImportBatchEntry_CTRL.runBatchDryRun` would break. This is acceptable because BGE was an internal UI, not a public API.

## References

- PR #60: Remove legacy Batch Gift Entry, make Gift Entry always-on
- PR #58: Make Advanced Mapping always-on, remove Help Text mapping (Phase 1)
- PR #29: Remove Elevate Phase 1 (prior art for large-scale feature removal)
- [ADR-0007](0007-remove-legacy-rollups-and-rd1.md): Remove Legacy Rollups and RD1 (similar pattern)
