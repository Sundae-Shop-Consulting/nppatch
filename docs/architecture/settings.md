# Settings Reference

## Overview

NPPatch uses custom settings for configuration. Hierarchy custom settings allow both organization-level defaults and user-level overrides, while list custom settings store key-value configuration data like field mappings and naming patterns.

!!! info "How to Access Settings"
    Administrators manage NPPatch settings through the **NPPatch Settings** UI—accessible from the App Launcher or the NPPatch Settings tab. This interface provides a guided, organized view of all configuration options. While the underlying data is stored in Salesforce custom settings objects, most settings should be configured through the NPPatch Settings UI rather than the standard Custom Settings page in Setup.

## Settings Access in Code

### Via UTIL_CustomSettingsFacade

The recommended approach using a facade pattern:

```apex
// Get settings with user override fallback
Contacts_And_Orgs_Settings__c settings = UTIL_CustomSettingsFacade.getContactsSettings();

// If not found at user level, automatically falls back to org level
// If not found anywhere, returns new instance with defaults applied
```

### In Tests

Settings are cached in memory. Configure for tests:

```apex
Contacts_And_Orgs_Settings__c testSettings = new Contacts_And_Orgs_Settings__c(
    Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
    Payments_Enabled__c = true
);
UTIL_CustomSettingsFacade.getContactsSettingsForTests(testSettings);
```

## Contacts and Organizations Settings

**Object:** `Contacts_And_Orgs_Settings__c`
**Scope:** Hierarchy (user or organization level)
**Purpose:** Core constituent relationship configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Account_Processor__c` | Picklist | HH_ACCOUNT_PROCESSOR | How accounts are managed: "HH Account Model" or "One-to-One" |
| `Payments_Enabled__c` | Checkbox | true | Enable payment tracking via OppPayment__c |
| `Opportunity_Contact_Role_Default_role__c` | Text | "Donor" | Default role for opportunity contact roles |
| `Contact_Role_for_Organizational_Opps__c` | Text | "Soft Credit" | Role for contact relationships to org opps |
| `HH_Account_RecordTypeID__c` | ID | (dynamic) | Record type ID for household accounts |
| `Opp_RecTypes_Excluded_for_Payments__c` | Text | (empty) | Semicolon-separated opp record types to exclude from payments |
| `Opp_Types_Excluded_for_Payments__c` | Text | (empty) | Semicolon-separated opp types to exclude from payments |
| `Disable_Account_Model_Trigger__c` | Checkbox | false | Prevent account model triggers from running |
| `Automatic_Campaign_Member_Management__c` | Checkbox | false | Auto-add contacts to campaigns |
| `Campaign_Member_Responded_Status__c` | Text | (empty) | Campaign member status for responses |
| `Campaign_Member_Non_Responded_Status__c` | Text | (empty) | Campaign member status for non-responses |
| `Organizational_Account_Addresses_Enabled__c` | Checkbox | false | Allow addresses on org accounts |
| `Household_Account_Addresses_Disabled__c` | Checkbox | false | Disable addresses on household accounts |
| `Simple_Address_Change_Treated_as_Update__c` | Checkbox | false | Simple address updates don't create new Address__c |
| `Enforce_Accounting_Data_Consistency__c` | Checkbox | false | Validate accounting field consistency |

## Households Settings

**Object:** `Households_Settings__c`
**Scope:** Hierarchy
**Purpose:** Household object configuration and naming

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Household_Rules__c` | Picklist | NO_HOUSEHOLDS_PROCESSOR | When to create households (don't create, on all, on individuals) |
| `Household_Member_Contact_Role__c` | Text | "Household Member" | OCR role for household members |
| `Always_Rollup_to_Primary_Contact__c` | Checkbox | false | Always sum opps to primary contact |
| `Enable_Opp_Rollup_Triggers__c` | Checkbox | true | Enable opportunity rollup calculations |
| `Rollup_N_Day_Value__c` | Number | 365 | Days of history for rollup calculations |
| `Membership_Grace_Period__c` | Number | 30 | Days after membership expires before lapsed |
| `Membership_Record_Types__c` | Text | (empty) | Record types to treat as memberships |
| `Advanced_Household_Naming__c` | Checkbox | true | Use advanced naming (vs. simple name concatenation) |
| `Async_Household_Naming__c` | Checkbox | false | Queue household naming jobs asynchronously |
| `Schedule_Job_Limit__c` | Number | 25 | Max scheduled naming jobs |
| `Excluded_Contact_Opp_Rectypes__c` | Text | (empty) | Record types excluded from contact rollups |
| `Excluded_Contact_Opp_Types__c` | Text | (empty) | Opportunity types excluded from contact rollups |
| `Excluded_Account_Opp_Rectypes__c` | Text | (empty) | Record types excluded from account rollups |
| `Excluded_Account_Opp_Types__c` | Text | (empty) | Opportunity types excluded from account rollups |
| `Household_Contact_Roles_On__c` | Checkbox | true | Enable contact roles on households |
| `Household_OCR_Excluded_Recordtypes__c` | Text | (empty) | Record types excluded from household OCRs |
| `Household_Creation_Excluded_Recordtypes__c` | Text | (empty) | Record types that don't create households |
| `Enable_Soft_Credit_Rollups__c` | Checkbox | true | Roll up soft credits to contacts |
| `Soft_Credit_Roles__c` | Text | "Matched Donor;Soft Credit;Household Member" | Roles that count as soft credits |
| `Matched_Donor_Role__c` | Text | "Matched Donor" | Specific matched donor role |
| `Seasonal_Addresses_Batch_Size__c` | Number | 10 | Batch size for seasonal address processing |

## Recurring Donations Settings

**Object:** `Recurring_Donations_Settings__c`
**Scope:** Hierarchy
**Purpose:** Recurring donation behavior and scheduling

NPPatch uses Enhanced Recurring Donations (RD2) exclusively—there is no legacy engine to configure or migrate from. All of the fields below apply to the current recurring donations implementation.

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Open_Opportunity_Behavior__c` | Picklist | "Mark Opportunities Closed Lost" | How to close open installment opps when an RD is closed |
| `Add_Campaign_to_All_Opportunites__c` | Checkbox | true | Attach campaign to all generated installment opps |
| `Maximum_Donations__c` | Number | 50 | Max installments to generate at once |
| `Recurring_Donation_Batch_Size__c` | Number | 50 | Batch size for RD processing |
| `Opportunity_Forecast_Months__c` | Number | 12 | Months forward to forecast installments |
| `InstallmentOppAutoCreateOption__c` | Picklist | "Always_Create_Next_Installment" | When to auto-create the next installment |
| `InstallmentOppFirstCreateMode__c` | Picklist | "Synchronous" | Create first installment synchronously or async |
| `DisableRollupsWhenCreatingInstallments__c` | Checkbox | false | Skip rollups during installment creation |
| `NextDonationDateMatchRangeDays__c` | Number | 0 | Days before/after to match the next donation date |
| `EnableAutomaticNaming__c` | Checkbox | false | Auto-generate RD names from donor |
| `EnableChangeLog__c` | Checkbox | false | Create RecurringDonationChangeLog__c records on changes |
| `ExcludeClosedRecurringDonations__c` | Checkbox | false | Exclude closed RDs from forecast |
| `UseFiscalYearForRecurringDonationValue__c` | Checkbox | false | Use fiscal year for RD amount calculations |
| `Record_Type__c` | ID | (first active) | Record type ID for generated installment opportunities |
| `InstallmentOppStageName__c` | Text | (label default) | Stage name for auto-created installment opportunities |

### Status Automation Fields

| Field | Purpose |
|-------|---------|
| `StatusAutomationDaysForLapsed__c` | Days of inactivity before automatically setting status to the lapsed value |
| `StatusAutomationDaysForClosed__c` | Days of inactivity before automatically setting status to the closed value |
| `StatusAutomationLapsedValue__c` | The status picklist value to assign when an RD lapses |
| `StatusAutomationClosedValue__c` | The status picklist value to assign when an RD closes |

Status automation is configured through the **NPPatch Settings > Recurring Donations > Status Automation** panel.

## Relationship Settings

**Object:** `Relationship_Settings__c`
**Scope:** Hierarchy
**Purpose:** Relationship record configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Reciprocal_Method__c` | Picklist | "List Setting" | How to determine reciprocal relationships |
| `Gender_Field__c` | Text | (empty) | Contact field to use for gender-specific reciprocals |

**Reciprocal Methods:**
- `List Setting` — use custom setting list for mappings
- `Value Inversion` — swap relationship type (e.g., "Parent" ↔ "Child")

## Affiliations Settings

**Object:** `Affiliations_Settings__c`
**Scope:** Hierarchy
**Purpose:** Affiliation record automation

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Automatic_Affiliation_Creation_Turned_On__c` | Checkbox | true | Auto-create Affiliation when Contact Account Name populated |

## Error Handling Settings

**Object:** `Error_Settings__c`
**Scope:** Hierarchy
**Purpose:** Exception handling and logging configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Store_Errors_On__c` | Checkbox | true | Write errors to Error__c object |
| `Error_Notifications_On__c` | Checkbox | true | Send email notifications for errors |
| `Error_Notifications_To__c` | Picklist | "All System Admins" | Who to notify (all admins, specific user, specific role) |
| `Disable_Error_Handling__c` | Checkbox | false | Completely disable error handling (not recommended) |
| `Enable_Debug__c` | Checkbox | false | Enable additional debug logging |
| `Respect_Duplicate_Rule_Settings__c` | Checkbox | false | Honor duplicate rules in error handling |

## Household Naming Settings

**Object:** `Household_Naming_Settings__c`
**Scope:** Hierarchy
**Purpose:** Household name and greeting format configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Household_Name_Format__c` | Text | "{!LastName} Household" | Template for household names |
| `Formal_Greeting_Format__c` | Text | "{!{!Salutation} {!FirstName}} {!LastName}" | Formal greeting template |
| `Informal_Greeting_Format__c` | Text | "{!{!FirstName}}" | Informal greeting template |
| `Name_Connector__c` | Text | " and " | Text between contact names |
| `Name_Overrun__c` | Text | " and Family" | Text when too many contacts |
| `Contact_Overrun_Count__c` | Number | 9 | How many contacts before overrun |
| `Implementing_Class__c` | Text | "HH_NameSpec" | Class that implements naming logic |

**Template Tokens:**
- `{!LastName}` — Contact's last name
- `{!FirstName}` — Contact's first name
- `{!Salutation}` — Contact's salutation (Mr., Ms., etc.)

## Allocations Settings

**Object:** `Allocations_Settings__c`
**Scope:** Hierarchy
**Purpose:** Opportunity allocation configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Default_Allocations_Enabled__c` | Checkbox | false | Create default allocation on all opps |
| `Default__c` | ID | (empty) | Default General_Accounting_Unit__c |
| `Payment_Allocations_Enabled__c` | Checkbox | false | Enable allocations on payments |
| `Excluded_Opp_RecTypes__c` | Text | (empty) | Record types excluded from allocations |
| `Excluded_Opp_Types__c` | Text | (empty) | Opportunity types excluded from allocations |
| `Rollup_N_Day_Value__c` | Number | 365 | Days of history for rollup calculations |
| `Use_Fiscal_Year_for_Rollups__c` | Checkbox | false | Use fiscal year for rollup calculations |

## Address Verification Settings

**Object:** `Addr_Verification_Settings__c`
**Scope:** Hierarchy
**Purpose:** Address verification service configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Enable_Automatic_Verification__c` | Checkbox | false | Auto-verify addresses on save |
| `Reject_Ambiguous_Addresses__c` | Checkbox | false | Prevent saving ambiguous address matches |

NPPatch includes validators for Google (requires a user-provided API key) and Cicero (requires a user-provided API key). The SmartyStreets integration from the original NPSP codebase has been removed; organizations that previously used SmartyStreets should configure the Google or Cicero validator, or implement a custom validator using the `ADDR_IValidator` interface.

See **NPPatch Settings > People > Address Verification** to configure your validator and API keys.

## Customizable Rollup Settings

**Object:** `Customizable_Rollup_Settings__c`
**Scope:** Hierarchy
**Purpose:** Rollup calculation engine configuration

NPPatch uses the Customizable Rollup (CRLP) engine exclusively. There is no legacy rollup engine to enable or migrate from. The `Customizable_Rollups_Enabled__c` field exists in the schema for historical reasons but its value has no effect—the CRLP engine always runs.

Rollup definitions (86 `Rollup__mdt` records, 8 `Filter_Group__mdt` records, and 12 `Filter_Rule__mdt` records) deploy with the package, so rollups work on a fresh install without any additional configuration steps. If you need to restore defaults after modification, use the **Reset to Defaults** button in **NPPatch Settings > Donations > Customizable Rollups**.

### Batch Size Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Rollups_Account_Batch_Size__c` | Number | 200 | Batch size for account rollup processing |
| `Rollups_Contact_Batch_Size__c` | Number | 200 | Batch size for contact rollup processing |
| `Rollups_Account_SkewMode_Batch_Size__c` | Number | 1000 | Batch size for skew-mode account processing |
| `Rollups_Contact_SkewMode_Batch_Size__c` | Number | 1000 | Batch size for skew-mode contact processing |
| `Rollups_Account_Soft_Credit_Batch_Size__c` | Number | 200 | Batch size for soft credit rollups |
| `Rollups_Contact_Soft_Credit_Batch_Size__c` | Number | 200 | Batch size for contact soft credit rollups |
| `Rollups_GAU_Batch_Size__c` | Number | 200 | Batch size for GAU rollup processing |
| `Rollups_Skew_Dispatcher_Batch_Size__c` | Number | 300 | Batch size for skew dispatcher |
| `Rollups_Limit_on_Attached_Opps_for_Skew__c` | Number | 250 | Max opps before using skew mode |
| `Disable_Related_Records_Filter__c` | Checkbox | false | Include unrelated records in rollups |
| `AccountHardCreditNonSkew_Incremental__c` | Checkbox | true | Use incremental hard credit calculations |
| `ContactHardCreditNonSkew_Incremental__c` | Checkbox | true | Use incremental contact hard credits |
| `LimitRecalculatedRecurringDonations__c` | Checkbox | false | Limit RD recalculations |
| `RecurringDonationLastNDays__c` | Number | 31 | Days of RD history to process |

## Gift Entry Settings

**Object:** `Gift_Entry_Settings__c`
**Scope:** Hierarchy
**Purpose:** Gift entry configuration

Gift Entry is always enabled in NPPatch. There is no toggle to turn it on or off.

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Default_Gift_Entry_Template__c` | ID | (empty) | Default form template for gift entry |

## Levels Settings

**Object:** `Levels_Settings__c`
**Scope:** Hierarchy
**Purpose:** Donor level assignment configuration

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Level_Assignment_Batch_Size__c` | Number | 200 | Batch size for level assignment processing |

## Initialization and Defaults

### Automatic Initialization

On first trigger execution, if custom settings are not found, TDTM automatically:

1. Calls `TDTM_DefaultConfig.getDefaultRecords()`
2. Inserts default `Trigger_Handler__c` configuration
3. Marks `defaultRecordsInserted = true`

This ensures minimal post-install configuration is required.

### Custom Settings Defaults

The `UTIL_CustomSettingsFacade` applies defaults when settings don't exist. These defaults are applied when creating new user-level settings, creating org-level settings if none exist, or initializing during tests.

## Configuration Best Practices

### Account Model

The most critical setting is `Contacts_And_Orgs_Settings__c.Account_Processor__c`:

| Value | Behavior | Best For |
|-------|----------|----------|
| `HH_ACCOUNT_PROCESSOR` | Household accounts | Organizations that organize by family unit |
| `ONE_TO_ONE_PROCESSOR` | Individual accounts per contact | Some service providers |

Once chosen, changing this affects all related data and code paths. Choose carefully.

### User-Level Overrides

Create user-level overrides in NPPatch Settings when specific users need different behavior. User-level settings take precedence over org defaults.

### Troubleshooting Settings Not Taking Effect

If a setting change doesn't appear to take effect, check whether a user-level override is hiding the org default:

```apex
Contacts_And_Orgs_Settings__c userSetting = Contacts_And_Orgs_Settings__c.getInstance();
System.debug('User setting ID: ' + userSetting.Id);
```

Custom settings don't count against SOQL query limits, so you can query them freely for debugging.

## Related Documentation

- [Data Model](data-model.md) — Custom objects and fields
- [Technical Overview](overview.md) — Settings management patterns
- [Trigger Framework](trigger-framework.md) — How handlers access settings

---

*If you see something that could be improved, please create an issue or email admin@nppatch.com.*
