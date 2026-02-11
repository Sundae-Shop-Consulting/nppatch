# Settings Reference

## Overview

NPPatch uses **21 hierarchy custom settings** for configuration. Hierarchy custom settings allow both organization-level defaults and user-level overrides, balancing global consistency with individual flexibility.

## Settings Access

### Via UTIL_CustomSettingsFacade

The recommended approach using a facade pattern:

```apex
// Get settings with user override fallback
Contacts_And_Orgs_Settings__c settings = UTIL_CustomSettingsFacade.getContactsSettings();

// If not found at user level, automatically falls back to org level
// If not found anywhere, returns new instance with defaults applied
```

### Direct Query

For advanced usage:

```apex
// User-level (preferred if exists)
Contacts_And_Orgs_Settings__c userSettings = Contacts_And_Orgs_Settings__c.getInstance();

// Organization-level (fallback)
Contacts_And_Orgs_Settings__c orgSettings = Contacts_And_Orgs_Settings__c.getOrgDefaults();
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
| `Account_Processor__c` | Picklist | HH_ACCOUNT_PROCESSOR | How accounts are managed: "HH Account Model", "One-to-One", or "Household Account" |
| `Payments_Enabled__c` | Checkbox | true | Enable payment tracking via OppPayment__c |
| `Enable_Opportunity_Contact_Role_Trigger__c` | Checkbox | false | (Deprecated - typically disabled) |
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

### Configuration via UI

Navigate to **Setup > Custom > Custom Settings > Contacts and Organizations Settings**:

1. Click "Manage" next to org default
2. Edit settings to match your account model
3. Save changes

For user overrides, click "New" to create user-specific settings.

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
**Purpose:** Recurring donation behavior (v1 and v2 features)

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `IsRecurringDonations2Enabled__c` | Checkbox | false | Enable v2 recurring donation engine (major feature switch) |
| `Open_Opportunity_Behavior__c` | Picklist | "Mark Opportunities Closed Lost" | How to close old opps when new ones created |
| `Add_Campaign_to_All_Opportunites__c` | Checkbox | true | Attach campaign to all generated opps |
| `Maximum_Donations__c` | Number | 50 | Max installments to generate at once |
| `Recurring_Donation_Batch_Size__c` | Number | 50 | Batch size for RD processing |
| `DataMigrationBatchSize__c` | Number | 25 | Batch size for v1-to-v2 migration |
| `Opportunity_Forecast_Months__c` | Number | 12 | Months forward to forecast RDs |
| `InstallmentOppAutoCreateOption__c` | Picklist | "Always_Create_Next_Installment" | When to auto-create next installment |
| `InstallmentOppFirstCreateMode__c` | Picklist | "Synchronous" | Create first installment synchronously or async |
| `DisableRollupsWhenCreatingInstallments__c` | Checkbox | false | Skip rollups during installment creation |
| `NextDonationDateMatchRangeDays__c` | Number | 0 | Days to match next donation date |
| `EnableAutomaticNaming__c` | Checkbox | false | Auto-generate RD names from donor |
| `EnableChangeLog__c` | Checkbox | false | Create RecurringDonationChangeLog__c records |
| `ExcludeClosedRecurringDonations__c` | Checkbox | false | Exclude closed RDs from forecast |
| `UseFiscalYearForRecurringDonationValue__c` | Checkbox | false | Use fiscal year for RD amount calculations |
| `Record_Type__c` | ID | (first active) | Record type ID for generated opportunities |

### RD v2 Status Mapping

Additional fields for RD2 status automation:

- `StatusMappingDeploymentId__c` - Deployment ID for status mappings
- `StatusAutomationDaysForLapsed__c` - Days before marking status lapsed
- `StatusAutomationDaysForClosed__c` - Days before marking status closed
- `StatusAutomationLapsedValue__c` - Status value for lapsed
- `StatusAutomationClosedValue__c` - Status value for closed

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
- `List Setting` - Use custom setting list for mappings
- `Value Inversion` - Swap relationship type (e.g., "Parent" ↔ "Child")

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
| `OverrideFeature_PilotEnabled__c` | Checkbox | false | Enable error override feature pilot |
| `Enable_Debug__c` | Checkbox | false | Enable additional debug logging |
| `Respect_Duplicate_Rule_Settings__c` | Checkbox | false | Honor duplicate rules in error handling |
| `DisableRecordDataHealthChecks__c` | Checkbox | false | Skip data health validation checks |

## Batch Data Entry Settings

**Object:** `Batch_Data_Entry_Settings__c`
**Scope:** Hierarchy
**Purpose:** Batch donation entry configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Allow_Blank_Opportunity_Names__c` | Checkbox | true | Allow donations without description |
| `Opportunity_Naming__c` | Checkbox | true | Auto-generate opportunity names |

## Address Verification Settings

**Object:** `Addr_Verification_Settings__c`
**Scope:** Hierarchy
**Purpose:** USPS address verification configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Enable_Automatic_Verification__c` | Checkbox | false | Auto-verify addresses on save |
| `Reject_Ambiguous_Addresses__c` | Checkbox | false | Prevent saving ambiguous address matches |

**Note:** Requires address verification service integration (external API).

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
- `{!LastName}` - Contact's last name
- `{!FirstName}` - Contact's first name
- `{!Salutation}` - Contact's salutation (Mr., Ms., etc.)

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

## Data Import Settings

**Object:** `Data_Import_Settings__c`
**Scope:** Hierarchy
**Purpose:** Batch data import configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Batch_Size__c` | Number | 50 | Records per batch during import |
| `Contact_Matching_Rule__c` | Text | "Firstname,Lastname,Email" | Fields used to match existing contacts |
| `Donation_Matching_Behavior__c` | Picklist | "Do Not Match" | How to match existing donations |
| `Donation_Matching_Rule__c` | Text | "Donation_Amount__c;Donation_Date__c" | Fields used for donation matching |
| `Donation_Date_Range__c` | Number | 0 | Days before/after to match donations |
| `Default_Data_Import_Field_Mapping_Set__c` | Text | (set name) | Default field mapping configuration |
| `Field_Mapping_Method__c` | Picklist | "Help Text" | How to populate field mappings ("Help Text" or "Data Import Field Mapping") |

**Matching Rule Format:**
- Semicolon-separated field names
- Can include namespace prefix: `nppatch__Donation_Amount__c`

## Customizable Rollup Settings

**Object:** `Customizable_Rollup_Settings__c`
**Scope:** Hierarchy
**Purpose:** Custom rollup calculation engine configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Customizable_Rollups_Enabled__c` | Checkbox | false | Enable CRLP rollup engine (major feature switch) |
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
| `CMT_API_Status__c` | Text | (empty) | Internal API status tracking |
| `AccountHardCreditNonSkew_Incremental__c` | Checkbox | true | Use incremental hard credit calculations |
| `ContactHardCreditNonSkew_Incremental__c` | Checkbox | true | Use incremental contact hard credits |
| `LimitRecalculatedRecurringDonations__c` | Checkbox | false | Limit RD recalculations |
| `RecurringDonationLastNDays__c` | Number | 31 | Days of RD history to process |

## Levels Settings

**Object:** `Levels_Settings__c`
**Scope:** Hierarchy
**Purpose:** Donor level assignment configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Level_Assignment_Batch_Size__c` | Number | 200 | Batch size for level assignment processing |

## Gift Entry Settings

**Object:** `Gift_Entry_Settings__c`
**Scope:** Hierarchy
**Purpose:** Modern gift entry interface configuration

### Key Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `Default_Gift_Entry_Template__c` | ID | (empty) | Default form template for gift entry |
| `Enable_Gateway_Assignment__c` | Checkbox | false | Enable payment gateway assignment in gift entry |

## Initialization and Defaults

### Automatic Initialization

On first trigger execution, if custom settings are not found, TDTM automatically:

1. Calls `TDTM_DefaultConfig.getDefaultRecords()`
2. Inserts default `Trigger_Handler__c` configuration
3. Marks `defaultRecordsInserted = true`

This ensures minimal post-install configuration required.

### Custom Settings Defaults

The `UTIL_CustomSettingsFacade` applies defaults when settings don't exist:

```apex
private static void configContactsSettings(Contacts_And_Orgs_Settings__c cs) {
    cs.Enable_Opportunity_Contact_Role_Trigger__c = false;
    cs.Payments_Enabled__c  = true;
    cs.Opportunity_Contact_Role_Default_role__c = 'Donor';
    cs.Account_Processor__c = 'HH_ACCOUNT_PROCESSOR';
    // ... more defaults
}
```

These defaults are applied when:
1. Creating new user-level settings
2. Creating org-level settings if none exist
3. Initializing during tests

## Configuration Best Practices

### 1. Start with Org-Level Defaults

Set up organization-level custom settings that apply to all users:

1. Navigate to **Setup > Custom > Custom Settings**
2. Choose a setting object
3. Click "Manage" next to "Org Default"
4. Click "Edit" and configure for your nonprofit

### 2. Override for Specific Users

Create user-level overrides when needed:

1. Click "New" to create a new setting record
2. Select the user
3. Configure user-specific values
4. Save

### 3. Test Settings Changes

Settings take effect immediately. Test in a sandbox first:

```apex
// In sandbox
Contacts_And_Orgs_Settings__c settings = UTIL_CustomSettingsFacade.getContactsSettings();
System.debug('Account Processor: ' + settings.Account_Processor__c);
```

### 4. Document Custom Configuration

If you customize any settings, document:
- Which settings you changed
- Why you changed them
- What values you used

This helps with troubleshooting and future upgrades.

### 5. Account Model Configuration

The most critical setting is `Contacts_And_Orgs_Settings__c.Account_Processor__c`:

| Value | Behavior | Best For |
|-------|----------|----------|
| `HH_ACCOUNT_PROCESSOR` | Household accounts | Organizations that organize by family unit |
| `ONE_TO_ONE_PROCESSOR` | Individual accounts per contact | Solo practitioners, some service providers |

**Once chosen, changing this affects all related data and code paths. Choose carefully.**

## Advanced Configuration

### CMT_API_Status Tracking

The `Customizable_Rollup_Settings__c.CMT_API_Status__c` field tracks the status of custom metadata API calls during CRLP configuration. This is typically managed automatically.

### Feature Flags

Some settings act as feature flags:

- `IsRecurringDonations2Enabled__c` - Switch between v1 and v2 engines
- `Customizable_Rollups_Enabled__c` - Enable CRLP engine
- `EnableChangeLog__c` - Start tracking RD changes
- `Enable_Debug__c` - Enable additional logging

**Enabling features is typically backward-compatible, but test before enabling in production.**

## Troubleshooting

### Settings Not Taking Effect

1. Check user-level override (may be hiding org default)
   ```apex
   Contacts_And_Orgs_Settings__c userSetting = Contacts_And_Orgs_Settings__c.getInstance();
   System.debug('User ID: ' + userSetting.Id);
   ```

2. Clear cache if using custom cache (reload page/reconnect)

3. Verify org defaults exist:
   ```apex
   Contacts_And_Orgs_Settings__c orgSettings = UTIL_CustomSettingsFacade.getOrgContactsSettings();
   System.debug(orgSettings);
   ```

### Settings Query Limit

Custom settings don't count against SOQL query limits, so use them freely:

```apex
// These don't count against query limit
Contacts_And_Orgs_Settings__c settings = UTIL_CustomSettingsFacade.getContactsSettings();
Households_Settings__c hhSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();
Error_Settings__c errSettings = UTIL_CustomSettingsFacade.getErrorSettings();
```

### Resetting to Defaults

To reset a setting to defaults:

1. Delete the custom setting record
2. Code will re-initialize on next access
3. Or manually re-configure via Setup UI

## Related Documentation

- [Data Model](/architecture/data-model/) - Custom objects and fields
- [Technical Overview](/architecture/overview/) - Settings management patterns
- [Trigger Framework](/architecture/trigger-framework/) - How handlers access settings

---

*This documentation was generated by AI and still needs human review. If you see something that could be improved, please create an issue or email admin@nppatch.com.*
