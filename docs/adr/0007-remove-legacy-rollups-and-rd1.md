# ADR-0007: Remove Legacy Rollups (RLLP) and Legacy Recurring Donations (RD1)

**Status:** Accepted
**Date:** 2026-02-22

## Context

NPSP shipped two generations of both its rollup engine and its recurring donations feature. In each case, the newer version was built as a parallel replacement, and NPSP retained the legacy code behind a feature flag so existing orgs could migrate at their own pace.

### Dual rollup engines

1. **Legacy NPSP Rollups (`RLLP_*`)** — the original engine, using Apex aggregate queries and batch classes to calculate donor statistics
2. **Customizable Rollups (`CRLP_*`)** — the replacement, using Custom Metadata Types (`Rollup__mdt`, `Filter_Group__mdt`, `Filter_Rule__mdt`) to define rollup calculations declaratively

The `Customizable_Rollup_Settings__c.Customizable_Rollups_Enabled__c` flag controlled which engine ran. Approximately 50 code locations checked this flag, branching between CRLP and legacy paths. A **User Defined Rollups (UDR)** settings panel existed solely to convert legacy rollup customizations into CRLP metadata during migration.

### Dual recurring donation engines

1. **Legacy Recurring Donations (RD1)** (`RD_*` classes) — the original engine with fixed installment schedules
2. **Enhanced Recurring Donations (RD2)** (`RD2_*` classes) — the replacement with flexible schedules, pause/resume, and change log tracking

The `isRecurringDonations2Enabled` flag controlled which engine ran. RD1→RD2 migration infrastructure (`RD2_DataMigration*`, `RD2_EnablementService`, `RD2_EnablementDelegate*`) existed to help orgs convert their data.

### Why remove now

NPPatch is a greenfield fork with no production installs. There are no existing orgs running legacy rollups or RD1 that need migration support. Keeping both engines:

- Doubles the code surface area for rollup and recurring donation features
- Requires maintaining feature flags, dual code paths, and migration tooling that will never be used
- Makes settings UI confusing with enable/disable toggles and migration warnings
- Increases test execution time with tests for unused code

## Decision

### Make CRLP unconditionally enabled and remove legacy rollups

1. **Hardcode `isCustomizableRollupEngineEnabled` to `true`**, then remove the property entirely along with all guard checks
2. **Delete all 12 `RLLP_*` classes** and their tests (~6,000 lines)
3. **Delete `ALLO_Rollup_SCHED`** — a no-op class left over from the legacy GAU rollup path
4. **Remove the UDR settings panel** (`STG_PanelUserRollup`) and the `buildUserDefinedRollups()` method from `CRLP_DefaultConfigBuilder_SVC` — these only existed for legacy-to-CRLP migration
5. **Remove `enable()` and `disable()` methods** from `CRLP_EnablementService` — only `reset()` remains
6. **Remove the CRLP toggle** from the settings UI — the panel now shows only the rollup setup link and a "Reset to Defaults" button
7. **Replace `RLLP_OppRollup` facade calls** in kept classes (Households, CON_ContactMerge_TDTM, ContactAdapter, LegacyHouseholds) with direct `CRLP_RollupQueueable` calls
8. **Remove if/else branching** on the CRLP flag from batch controllers, schedulers, TDTM handlers, and ~10 other classes
9. **Add default CRLP rollup CMDT records to source** — 106 Custom Metadata records (86 Rollup, 8 Filter Group, 12 Filter Rule) now deploy with the package instead of requiring manual enablement
10. **Remove legacy scheduled job abort entries** — no production installs means no legacy jobs to clean up

### Make RD2 unconditionally enabled and remove RD1

1. **Delete all `RD_*` legacy classes** (~15 classes, ~5,000 lines) and their tests
2. **Delete RD1→RD2 migration infrastructure** (`RD2_DataMigration*`, `RD2_EnablementService`, `RD2_EnablementDelegate*`)
3. **Delete RD1 settings panels** (STG_PanelRD, STG_PanelRDBatch, STG_PanelRDCustomInstallment, STG_PanelRDCustomFieldMapping, STG_PanelRD2Enablement)
4. **Delete RD1 Visualforce pages** (RD_AddDonationsBTN, CRLP_RollupRD_BTN)
5. **Remove RD2 migration custom setting fields** (DataMigrationBatchSize, EnablementState, MigrationState)
6. **Incorporate `rd2_post_config` metadata** (flexipage, layout, object fields) directly into package source
7. **Remove `isRecurringDonations2Enabled` checks** from kept classes

### What we kept

- `Customizable_Rollup_Settings__c.Customizable_Rollups_Enabled__c` field — referenced in 47+ files; simpler to keep the field than clean up all references. The property just always returns `true`.
- `CRLP_DefaultConfigBuilder` and `CRLP_DefaultConfigBuilder_SVC` — still used by the "Reset to Defaults" button to regenerate CMDT records
- `UTIL_AbstractRollup_BATCH` — still extended by `CRLP_RollupBatch_SVC`
- `User_Rollup_Field_Settings__c` custom setting object — metadata still exists, just no UI or code references
- All `RD2_*` classes — these are the active recurring donations engine

## Consequences

### Positive

- **~25,000 lines deleted** across ~130 files — significant reduction in code surface area
- **No dual code paths** — every rollup and recurring donation operation takes a single path
- **Simpler settings UI** — no migration toggles, enable/disable buttons, or legacy warnings
- **Rollup definitions deploy with the package** — new installs get working rollups immediately without manual enablement
- **Faster CI** — fewer classes to compile and test

### Negative

- **No rollback to legacy engines** — if a bug is found in CRLP or RD2, the legacy fallback is gone. This is acceptable because CRLP and RD2 are mature, well-tested engines, and NPPatch has no production data at risk.
- **"Reset to Defaults" recreates records that also exist in source** — the builder will update existing CMDT records rather than create duplicates, so this is harmless but slightly redundant.

## References

- PR #53: Remove legacy Recurring Donations (RD1) and legacy NPSP Rollups (RLLP)
- PR #29: Remove Elevate Phase 1 (prior art for large-scale feature removal)
- [docs/features/customizable-rollups.md](../features/customizable-rollups.md)
- [docs/features/recurring-donations.md](../features/recurring-donations.md)
