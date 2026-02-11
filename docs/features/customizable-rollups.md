# Customizable Rollups

Customizable Rollups (CRLP) automatically calculate aggregate values from donation records and summarize them to donor records. Organizations can define which fields to calculate, which source objects to aggregate, and which target records to update—all without custom code.

## Overview

Rollups aggregate donation-related data to create summary information on parent records. The system supports:

- **Calculations**: Totals, counts, averages, minimum, maximum values
- **Source Objects**: Opportunities, payments, recurring donations
- **Target Objects**: Accounts, contacts, General Accounting Units (GAUs), recurring donations
- **Filtering**: Complex filters to exclude certain donations from calculations
- **Batch Processing**: Recalculation of all rollups or filtered subsets

## Key Concepts

### Rollup Definition (Rollup__mdt)

Custom metadata type defining a single rollup calculation:

| Field | Purpose |
|-------|---------|
| `MasterLabel` | Display name |
| `Calculation_Type__c` | SUM, COUNT, AVG, MIN, MAX, BEST_YEAR, BEST_DAY, ANY |
| `Amount_Field__c` | Field to calculate (e.g., Opportunity.Amount) |
| `Detail_Object__c` | Source object (Opportunity, OppPayment__c, Recurring_Donation__c) |
| `Summary_Object__c` | Target object (Account, Contact, GAU__c, Recurring_Donation__c) |
| `Summary_Field__c` | Field to update with result |
| `Is_Deleted__c` | Soft delete flag for rollup |
| `Filter_Groups__c` | JSON reference to Filter_Group__mdt for filtering |
| `Is_Customizable__c` | Allows org customization vs. managed only |

### Calculation Types

| Type | Purpose | Example |
|------|---------|---------|
| SUM | Total of amount field | Total donations |
| COUNT | Number of qualifying records | Number of gifts |
| AVG | Average value | Average gift size |
| MIN | Smallest value | Smallest donation |
| MAX | Largest value | Largest donation |
| BEST_YEAR | Year with highest total | Best giving year |
| BEST_DAY | Most recent donation date | Last gift date |
| ANY | Whether any records match | Has pledged |

### Supported Source Objects

| Object | Fields | Notes |
|--------|--------|-------|
| Opportunity | Amount, CloseDate, StageName, RecordType | Primary donation object |
| OppPayment__c | Payment_Amount__c, Payment_Date__c | Payment-level rollups |
| Recurring_Donation__c | Amount__c, StartDate__c | Recurring commitment analysis |

### Supported Target Objects

| Object | Common Rollups | Use Cases |
|--------|----------------|-----------|
| Account | Lifetime value, Total gifts, Best year | Donor analysis, reporting |
| Contact | Lifetime value, Total gifts, Last gift date | Stewardship, segmentation |
| General_Accounting_Unit__c (GAU) | Fund balance, Total allocated | Fund management |
| Recurring_Donation__c | Total gifts, Last gift, Next expected | Recurring analysis |

## Filter Groups and Filter Rules

### Filter_Group__mdt

Groups multiple filter conditions for rollup filtering:

| Field | Purpose |
|-------|---------|
| `DeveloperName` | Unique identifier |
| `MasterLabel` | Display name |
| `Filter_Rules__r` | Related Filter_Rule__mdt records |

### Filter_Rule__mdt

Individual filter conditions:

| Field | Purpose |
|-------|---------|
| `DeveloperName` | Unique identifier |
| `MasterLabel` | Display name |
| `Filter_Group__c` | Parent filter group |
| `Field_to_Filter__c` | SObject field path (e.g., Opportunity.RecordType.DeveloperName) |
| `Operator__c` | equals, not_equals, greater_than, less_than, in_list, etc. |
| `Filter_Value__c` | Value to compare |
| `Relationship__c` | AND or OR logic with other rules in group |

### Filter Examples

**Example 1: Exclude grants and pledges**

```
Filter Group: "Contributions Only"
  Rule 1: Opportunity.RecordType.DeveloperName NOT_EQUALS "Grant"
  Rule 2: Opportunity.StageName NOT_EQUALS "Pledged"
  Logic: AND
```

**Example 2: Recent donations (last 2 years)**

```
Filter Group: "Recent Giving"
  Rule 1: Opportunity.CloseDate GREATER_THAN_OR_EQUAL relative_date:TODAY-730
  Logic: AND
```

## Rollup Processor

The `CRLP_RollupProcessor` class executes rollup calculations:

### Processing Steps

1. **Initialization**: Load rollup definitions and target records
2. **Detail Retrieval**: Query source objects (opportunities, payments) for each target
3. **Filtering**: Apply filter groups to exclude non-qualifying records
4. **Calculation**: Execute SUM, COUNT, AVG, etc. on filtered records
5. **Update**: Apply calculated values to target record fields
6. **Batch Processing**: Handle large data volumes in configurable batch sizes

### Batch Job Modes

| Mode | Use Case | Scale |
|------|----------|-------|
| NonSkewMode | Standard-volume orgs | Small to medium |
| LDV Mode | Large data volume (skewed accounts) | Enterprise |

The processor automatically detects account skew (some accounts with 100k+ opportunities) and uses optimized query strategies.

### RollupType Options

| Type | Trigger | Use Case |
|------|---------|----------|
| AccountContactRollup | After opportunity changes | Update account/contact totals |
| AccountSoftCreditRollup | After soft credit changes | Account secondary gift attribution |
| GAURollup | After allocation changes | Fund balance calculations |
| RecurringDonationRollup | After recurring donation changes | Recurring commitment analysis |

## Batch Processing

### CRLP_Account_BATCH

Batch job for recalculating rollups:

```apex
CRLP_Account_BATCH batch = new CRLP_Account_BATCH();
Database.executeBatch(batch, 200);
```

Processes accounts and recalculates all associated rollups.

### Recalculation Button

The Manage Rollups UI includes a `crlpRecalculateBTN` button allowing:

- **Full Recalculation**: Refresh all rollups for all records
- **Filtered Recalculation**: Refresh rollups only for selected record types
- **Date Range**: Optionally limit to recent records
- **Background Processing**: Async batch job queuing

## Configuration and Settings

### Customizable_Rollup_Settings__c

Organization-wide rollup settings:

| Setting | Purpose |
|---------|---------|
| Customizable Rollups Enabled | Activates CRLP vs. legacy rollups |
| Default Rollup Account Batch Size | Records per batch job chunk |
| Rollup Batch Job Size | Opportunities per inner batch |
| Enable Dry Run Mode | Preview rollup results without saving |

### Default Rollups

The system includes predefined rollups for common scenarios:

| Rollup | Calculation | Fields Updated |
|--------|-----------|-----------------|
| Lifetime Value | SUM of Opportunity.Amount | Account.Total_Donations_Lifetime__c |
| Number of Gifts | COUNT of Opportunities | Account.Number_of_Household_Members__c |
| Largest Gift | MAX of Opportunity.Amount | Account.LargestGift__c |
| Last Gift Date | BEST_DAY of Opportunity | Account.LastGiftDate__c |
| Best Year | BEST_YEAR of Opportunity | Account.GreatestGiftYear__c |
| Last Gift Paid | BEST_DAY filtered to paid | Account.LastGiftPaid__c |

### CRLP_DefaultConfigBuilder

Generates default rollup configuration on package installation:

- Creates standard rollup definitions for common donor metrics
- Establishes filter groups for common scenarios
- Generates filter rules for best practices

## Legacy vs. Customizable Rollups

### Migration Path

Organizations upgrading from legacy rollups:

1. **Legacy Rollups**: Pre-defined rollups with limited customization
2. **Customizable Rollups**: Fully flexible configuration via metadata
3. **Coexistence**: Both can run during transition
4. **Switch-Over**: Enable CRLP and disable legacy via settings

### Key Differences

| Aspect | Legacy | Customizable |
|--------|--------|--------------|
| Configuration | Apex code | Custom Metadata |
| Customization | Requires dev | Admin-friendly |
| Performance | Fixed | Optimized by mode |
| Filtering | Basic | Complex filters |
| Audit Trail | Limited | Change log support |

## API Service

### CRLP_ApiService

Programmatic access to rollup calculations:

```apex
CRLP_ApiService service = new CRLP_ApiService();
Map<Id, SObject> updatedRecords = service.performRollup(
    new Set<Id>{accountId},
    CRLP_RollupProcessingOptions.RollupType.AccountContactRollup
);
```

Enables:

- Trigger-based rollup execution
- Scheduled job triggered rollups
- External API-triggered calculations

## Performance Optimization

### Query Optimization

The processor uses:

- **Indexed Queries**: Queries on indexed fields (CreatedDate, Amount)
- **Batch Chunking**: Processes records in configured batch sizes
- **Related Queries**: Efficient related record retrieval

### Caching

- Rollup definitions cached in process memory
- Filter group compilation cached
- Related record maps cached during processor instance

### LDV Handling

For large data volumes:

- **Parent Record Chunking**: Process high-volume parents separately
- **Detail Query Limits**: Batch detail queries to avoid limits
- **Stateful Variables**: Retain state across batch chunks for accurate filtering

## Integration Points

- **Opportunities**: Primary source for donor-level rollups
- **Payments**: Payment amounts override opportunity amounts when present
- **Allocations**: GAU rollups aggregate allocated amounts
- **Recurring Donations**: Support rollups on recurring commitment values
- **Contacts/Accounts**: Primary rollup targets

## Reporting Applications

Common use cases for rollups:

**Donor Segmentation**: Use lifetime value rollups to segment donors by giving level.

**Fund Balance Reporting**: GAU rollups show allocated balance across all funds.

**Stewardship**: Last gift date and largest gift identify cultivation targets.

**Recurring Donor Analysis**: Rollups on recurring donations show monthly commitment totals.

**Year-over-Year**: Best year rollups enable annual giving trend analysis.
