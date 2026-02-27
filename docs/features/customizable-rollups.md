# Customizable Rollups

Customizable Rollups (CRLP) automatically calculate aggregate values from donation records and summarize them to donor records. Organizations can define which fields to calculate, which source objects to aggregate, and which target records to update—all through declarative configuration in Custom Metadata Types, without writing code.

CRLP is always enabled in NPPatch and deploys with a full set of default rollup definitions. A fresh install has working donor statistics rollups immediately, with no additional setup required.

## Overview

Rollups aggregate donation-related data to produce summary information on parent records. The system supports:

- **Calculation types** — totals, counts, averages, minimums, maximums, best year, best day, and others
- **Source objects** — Opportunities, Payments (`OppPayment__c`), recurring donations
- **Target objects** — Accounts, Contacts, General Accounting Units (GAUs), recurring donations
- **Filtering** — complex filter conditions that exclude certain records from calculations
- **Batch processing** — recalculation of all rollups or filtered subsets

## Key Concepts

### Rollup__mdt

Each `Rollup__mdt` record defines a single rollup calculation:

| Field | Purpose |
|-------|---------|
| `MasterLabel` | Display name |
| `Calculation_Type__c` | SUM, COUNT, AVG, MIN, MAX, BEST_YEAR, BEST_DAY, YEARS_DONATED, DONOR_STREAK, ANY |
| `Amount_Field__c` | Field to aggregate (e.g., `Opportunity.Amount`) |
| `Amount_Object__c` | Object the amount field is on |
| `Detail_Object__c` | Source object (Opportunity, OppPayment__c, Recurring_Donation__c) |
| `Summary_Object__c` | Target object (Account, Contact, GAU, Recurring_Donation__c) |
| `Summary_Field__c` | Field on the target object to populate |
| `Filter_Group__c` | Optional reference to a Filter_Group__mdt for filtering |
| `Is_Deleted__c` | Soft-delete flag |

### Calculation Types

| Type | Result |
|------|--------|
| SUM | Sum of the amount field across qualifying records |
| COUNT | Number of qualifying records |
| AVG | Average of the amount field |
| MIN | Smallest value |
| MAX | Largest value |
| BEST_YEAR | Calendar (or fiscal) year with the highest total |
| BEST_DAY | Most recent date among qualifying records |
| YEARS_DONATED | Number of distinct years with at least one qualifying gift |
| DONOR_STREAK | Current consecutive years of giving |
| ANY | Whether any qualifying record exists (Boolean) |

### Supported Source Objects

| Object | Notes |
|--------|-------|
| `Opportunity` | Primary donation object |
| `OppPayment__c` | Payment-level rollups (when payments are enabled) |
| `Recurring_Donation__c` | Rollups on recurring commitment values |

### Supported Target Objects

| Object | Typical Use |
|--------|-------------|
| `Account` | Household or organization-level donor summaries |
| `Contact` | Individual donor summaries |
| `General_Accounting_Unit__c` | Fund balance and giving totals |
| `Recurring_Donation__c` | Rollups back to the recurring donation itself |

## Filter Groups and Filter Rules

### Filter_Group__mdt

Groups one or more filter conditions:

| Field | Purpose |
|-------|---------|
| `DeveloperName` | Unique identifier |
| `MasterLabel` | Display name |

### Filter_Rule__mdt

Individual filter conditions within a group:

| Field | Purpose |
|-------|---------|
| `Filter_Group__c` | Parent group |
| `Field_to_Filter__c` | SObject field path (e.g., `Opportunity.RecordType.DeveloperName`) |
| `Operator__c` | `equals`, `not_equals`, `greater_than`, `less_than`, `in_list`, `not_in_list`, etc. |
| `Filter_Value__c` | Value to compare against |

Multiple rules within a group are combined with AND logic.

## Default Rollup Definitions

NPPatch ships with 86 `Rollup__mdt` records, 8 `Filter_Group__mdt` records, and 12 `Filter_Rule__mdt` records deployed in source. These cover the most common donor statistics fields on Account and Contact, including lifetime giving totals, gift counts, largest gift, most recent gift date, first gift date, best giving year, and soft credit summaries.

If the default rollup definitions are ever modified or deleted and you need to restore them, use the **Reset to Defaults** button in **NPPatch Settings > Donations > Customizable Rollups**. This re-deploys all default Custom Metadata records via the Metadata API. The "Reset to Defaults" button in the settings UI is the only rollup-related control on that panel—there is no enable/disable toggle.

## Custom Rollup Configuration

Organizations can define custom rollups through the Rollup Setup page, accessible from the **Customizable Rollups** panel in NPPatch Settings. This Visualforce-based interface (backed by `CRLP_RollupSetup_CTRL`) allows you to:

- Create new rollup definitions targeting any field on Account, Contact, or GAU
- Add filter groups and rules to narrow which records are included
- Define custom filter groups for reuse across multiple rollups

Changes made through the Rollup Setup page are deployed as Custom Metadata Type updates via the Metadata API.

## How Rollups Execute

### Real-Time (Trigger-Based)

When an Opportunity or Payment is created or updated, `CRLP_Rollup_TDTM` queues a rollup recalculation for the affected parent records via `CRLP_RollupQueueable`. This keeps donor statistics up to date in near real-time after each transaction.

### Batch Processing

For full recalculation of all records (e.g., after a data migration or bulk update), NPPatch provides dedicated batch classes:

| Batch Class | Purpose |
|-------------|---------|
| `CRLP_Account_BATCH` | Account hard credit rollups |
| `CRLP_Contact_BATCH` | Contact hard credit rollups |
| `CRLP_Account_SoftCredit_BATCH` | Account soft credit rollups |
| `CRLP_Contact_SoftCredit_BATCH` | Contact soft credit rollups |
| `CRLP_Account_AccSoftCredit_BATCH` | Account-level soft credits |
| `CRLP_GAU_BATCH` | General Accounting Unit rollups |
| `CRLP_SkewDispatcher_BATCH` | Dispatcher for skew-mode accounts |

Batch jobs can be triggered manually from **NPPatch Settings > Donations > Rollup Batch**, or scheduled through **NPPatch Settings > Bulk Data Processes > Batch Process Settings**.

### Skew Mode

Accounts with an unusually large number of opportunities (above the threshold set in `Rollups_Limit_on_Attached_Opps_for_Skew__c`, default 250) are processed in "skew mode," which uses a different query strategy to avoid governor limit violations. The `CRLP_AccountSkew_BATCH` and related classes handle this automatically.

## Rollup Processor Architecture

The CRLP engine is composed of several collaborating classes:

- **`CRLP_Rollup`** — the core data structure representing a single rollup calculation in progress
- **`CRLP_RollupProcessor`** — executes rollup calculations for a set of detail records against a parent
- **`CRLP_RollupProcessor_SVC`** — orchestrates the processor across multiple parents
- **`CRLP_Operation_SVC`** — implements the math for each calculation type (SUM, COUNT, etc.)
- **`CRLP_Rollup_SEL`** — queries and caches `Rollup__mdt` definitions
- **`CMT_FilterRuleEvaluation_SVC`** — evaluates filter rules against individual records
- **`CRLP_Query_SEL`** — builds the SOQL queries needed to retrieve detail records for a given set of targets
- **`CRLP_RollupQueueable`** — queues asynchronous rollup recalculation from triggers

## Recalculate Button

Each Account and Contact record page includes a **Recalculate** quick action (backed by `CRLP_RecalculateBTN_CTRL`) that recalculates all rollups for that single record on demand. This is useful for troubleshooting or refreshing a specific donor's statistics after a manual data correction.

## API Access

`CRLP_ApiService` provides programmatic access to rollup calculations:

```apex
CRLP_ApiService apiService = new CRLP_ApiService();
apiService.setRollupStateAsStale(rollupTypes);
```

`CRLP_ApiExecuteRollups` exposes rollup execution through the Callable API, allowing external automation to trigger recalculations.

## Customizable Rollup Settings

Rollup behavior is configured through `Customizable_Rollup_Settings__c`, managed via **NPPatch Settings > Donations > Customizable Rollups** and **NPPatch Settings > Bulk Data Processes > Batch Process Settings**.

The most commonly adjusted settings are the batch size fields, which control how many records are processed per batch chunk. Larger batch sizes improve throughput but consume more governor limits per execution. The defaults (200 for standard mode, 1000 for skew mode) work well for most organizations.

See [Settings Reference](../architecture/settings.md#customizable-rollup-settings) for the full field list.

## Integration Points

- **Opportunities** — primary source for donor-level rollups
- **Payments** — payment amounts can be used instead of opportunity amounts when payments are enabled
- **Allocations** — GAU rollups aggregate allocated amounts
- **Recurring Donations** — recurring commitment values roll up to Account and Contact
- **Contacts/Accounts** — primary rollup targets; summary fields receive calculated values

---

*If you see something that could be improved, please create an issue or email admin@nppatch.com.*
