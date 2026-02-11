# Allocations

The Allocations feature enables nonprofits to divide donation amounts across multiple funds or initiatives. When a donor gives to a general fund, allocations automatically distribute the amount to designated funds for accounting and reporting purposes.

## Overview

Allocations represent the assignment of donation amounts to General Accounting Units (GAUs). Rather than requiring donors to specify how their gift is divided, allocations provide administrators with flexible control over fund distributions through:

- **Default Allocations**: Automatically apply preset splits to all donations
- **Payment-Level Allocations**: Split payment installments across funds
- **Manual Allocations**: Staff can manually adjust allocations after donation entry
- **Multi-Currency Support**: Allocations respect multi-currency organizations

## Core Objects

### Allocation__c

Individual allocation records representing a fund assignment:

| Field | Purpose |
|-------|---------|
| `Opportunity__c` | Link to donation opportunity |
| `OppPayment__c` | Optional link to specific payment |
| `General_Accounting_Unit__c` | Fund/GAU receiving the allocation |
| `Percent__c` | Percentage of donation (e.g., 50 for 50%) |
| `Amount__c` | Calculated allocation amount |
| `Status__c` | Allocated, Paid, Written Off |

### General_Accounting_Unit__c (GAU)

Funds or initiatives receiving allocations:

| Field | Purpose |
|-------|---------|
| `Name` | Fund name (e.g., "General Fund", "Scholarship Fund") |
| `Description__c` | Fund purpose and details |
| `Active__c` | Available for new allocations |
| `Accounting_Code__c` | Integration with external accounting systems |
| `GAU_Allocated_Balance__c` | Rollup of allocated amount |

## Default Allocations

### Allocation_Default__c

Configuration defining default allocation splits:

| Field | Purpose |
|-------|---------|
| `Opportunity__c` | When set, applies only to specific opp |
| `General_Accounting_Unit__c` | Default receiving GAU |
| `Percent__c` | Percentage for this GAU |
| `Is_Default__c` | Primary default vs. alternative |

### Default Allocation Logic

When a donation is created:

1. **Check Opportunity-Level Defaults**: If specific defaults exist for that opportunity, use them
2. **Check Account-Level Defaults**: If account has assigned defaults, apply them
3. **Check Organization Defaults**: If global defaults exist, apply them
4. **No Defaults**: Donation remains unallocated until manually assigned

### Multi-Fund Defaults

Organizations can define splits across multiple GAUs:

**Example: Default split new donations 40% Missions, 30% Local, 30% Administration**

```
Default 1: General Accounting Unit = Missions, Percent = 40
Default 2: General Accounting Unit = Local, Percent = 30
Default 3: General Accounting Unit = Administration, Percent = 30
```

The allocation system validates percentages sum to 100%.

## Payment-Level Allocations

### OppPayment__c Integration

When payments are enabled, allocations can be applied at payment level:

- **Payment-Specific Splits**: Different allocations for installments in multi-payment scenarios
- **Partial Payment Allocation**: Track which funds each payment went toward
- **Refund Reversal**: Allocations adjust when payments are refunded

### Multi-Installment Scenarios

For donors making installment payments:

1. Recurring donation creates base opportunity
2. Each payment (installment) can have different allocation splits
3. Allocation amounts calculated based on payment amount
4. Rollupsaggregate allocations by GAU for reporting

## Allocation Creation and Updates

### ALLO_AllocationsRetrievalService

Service for retrieving opportunities and their allocation data:

```apex
ALLO_AllocationsRetrievalService retrieval = new ALLO_AllocationsRetrievalService()
    .withOpportunities(opportunityIds)
    .retrieveData();
```

The service:

1. Queries opportunities with related allocations
2. Builds maps for efficient allocation updates
3. Retrieves payment data if payments enabled
4. Retrieves recurring donation context
5. Handles multi-currency calculations

### ALLO_AllocationsDMLService

Handles insertion and update of allocation records:

- Validates allocation percentages and amounts
- Handles multi-currency conversion if needed
- Updates related records (opportunity, payment, GAU)
- Respects field-level security

### ALLO_AllocationsUtil

Utility functions for allocation calculations:

- **Percentage to Amount Conversion**: Calculates amount from opportunity amount and percent
- **Amount Validation**: Ensures allocations don't exceed donation amount
- **Rollup Aggregation**: Sums allocations for GAU balance calculation
- **Multi-Currency Handling**: Currency-aware calculations

## Allocation Validation

### Validation Rules

Before saving allocations:

1. **Percentage Sum**: All allocations for an opportunity sum to 100% (or 0% if unallocated)
2. **Amount Range**: Allocated amounts don't exceed opportunity amount
3. **GAU Active**: Can only allocate to active GAUs
4. **Status Logic**: Allocated status requires amount, paid status requires payment
5. **Currency Match**: Payment currency matches opportunity currency

### Error Scenarios

Common allocation validation failures:

- Allocations exceed 100%
- Negative allocation amounts
- Attempt to allocate to inactive GAU
- Opportunity amount changed, affecting allocation validity

## Rollups to General Accounting Units

### GAU_Allocated_Balance__c Rollup

Automatically calculates total allocated to each GAU:

```
Sum of Allocation__c.Amount__c where
  Allocation__c.General_Accounting_Unit__c = GAU.Id AND
  Allocation__c.Status__c = 'Allocated'
```

The rollup:

- Updates when allocations are created or modified
- Respects allocation status (allocated vs. paid)
- Supports multi-currency totals
- Enables fund balance reporting

### Fund Balance Reporting

GAU rollups enable reporting such as:

- **Fund Balance**: How much has been allocated to each fund
- **Fund Spending**: Compare allocated to actually paid amounts
- **Fund Trends**: Year-over-year fund allocation changes
- **Fund Distribution**: Percentage of total giving to each fund

## Allocations Settings

### Allocations_Settings__c

Configuration for allocation behavior:

| Setting | Purpose |
|---------|---------|
| Allocations Enabled | Activates allocation feature |
| Allocations Default | Default GAU for unallocated donations |
| Exclude Opportunity Types | Record types excluded from allocations |
| Excluded_Opp_RecTypes__c | Record type IDs excluded |
| Excluded_Opp_Types__c | Opportunity types excluded |
| Default Allocation Amount | Default allocate 100%, split, or none |

### Excluded Record Types

Organizations can exclude certain opportunity types from allocations:

- **Pledges**: Track commitment before payment
- **Grants**: Already allocated through grant agreement
- **In-Kind Donations**: Non-cash items not allocated
- **Matching Gifts**: Processed separately

## Allocation Wrapper and Views

### ALLO_AllocationsWrapper

Data structure for efficient allocation processing:

- Maps of allocations by opportunity ID
- Maps of allocations by payment ID
- Related opportunity data
- Related GAU data
- Change tracking

### Allocation Display Components

The allocation UI components display:

- Current allocations with GAU names
- Allocation percentages and amounts
- Ability to add/remove/modify allocations
- Validation feedback

## Multi-Currency Support

### Currency Handling

For multi-currency organizations:

1. **Opportunity Currency**: Allocation uses opportunity currency
2. **Payment Currency**: If payment different currency, conversion applied
3. **GAU Rollup Currency**: Rollup sums converted to organization default currency
4. **Reporting Currency**: Allocations available in multiple currency views

### Currency Conversion

Allocations in non-default currency:

- Converted using Salesforce exchange rates
- Stored in original currency
- Rolled up in default currency
- Support for multi-currency report views

## Integration Points

- **Opportunities**: Allocations split opportunity amounts across funds
- **Payments**: Payment-level allocations for installment tracking
- **General Accounting Units**: Target funds for allocation
- **Recurring Donations**: Support allocations on recurring gift opportunities
- **Gift Entry**: Template-based allocation during import
- **Rollups**: GAU rollups aggregate allocated amounts
- **Reports**: Allocation data enables fund accounting reports

## Use Cases

**Unrestricted Gift Distribution**: When donor gives unrestricted, automatically distribute 50% to program expenses and 50% to administrative costs.

**Multi-Fund Campaigns**: During capital campaign, allocate gifts based on campaign fund assignment with override capability.

**Fund Balance Tracking**: Use GAU rollups to monitor fund balance and alert when fund reaches spending goal.

**Payment-Specific Allocation**: Multi-year pledges allocated 100% to specific fund for year 1, then reallocated in year 2.

**Grant Fund Segregation**: Allocate restricted grants separately from unrestricted gifts for compliance reporting.

**Accounting Integration**: Export allocations to external accounting system by GAU for fund accounting reconciliation.
