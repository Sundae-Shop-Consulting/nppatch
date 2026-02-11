# Recurring Donations

The Enhanced Recurring Donations (RD2) feature provides comprehensive management of commitments from donors who give repeatedly over time. The system automates opportunity creation, tracks payment schedules, manages recurring donation status, and logs all changes for audit purposes.

## Overview

Recurring donations in NPPatch represent ongoing financial commitments from contacts or accounts. Unlike opportunities that represent single transactions, recurring donations automatically generate installment opportunities at defined intervals, supporting both flexible and structured donation schedules.

### Key Concepts

- **Recurring Donation**: A record representing an ongoing commitment to donate
- **Installment Period**: The frequency at which donations occur (monthly, quarterly, annually, etc.)
- **Schedule**: The calculated dates and amounts for future donations based on the installment period
- **Donor Type**: Either Account (organizational) or Contact (individual) relationship
- **Sustainer Status**: Automatic tracking of active recurring donors for engagement analysis

## Recurring Donation Configuration

### Installment Periods and Frequency

The system supports multiple installment periods through the `RD2_Constants` class:

| Period | Frequency | Examples |
|--------|-----------|----------|
| Monthly | Every month | 12 donations per year |
| Quarterly | Every 3 months | 4 donations per year |
| Annually | Every 12 months | 1 donation per year |
| Weekly | Every 7 days | ~52 donations per year |
| Every 2 Weeks | Every 14 days | ~26 donations per year |

### Day-of-Month Scheduling

For monthly and quarterly donations, the system supports day-of-month selection:

- **Specific Day** (1-28): Donation created on that day each period
- **Last Day of Month**: Automatically adjusts for months with fewer days (e.g., February 28/29)
- **Custom Interval**: Configurable days between installments

### Recurring Donation Fields

Recurring donations track:

| Field | Purpose |
|-------|---------|
| `Amount__c` | The donation amount per installment |
| `Day_of_Month__c` | The day each month/quarter donations occur |
| `Installment_Frequency__c` | How many installments per period (e.g., 1 per month, 2 per month) |
| `Installment_Period__c` | The period for installments (monthly, quarterly, etc.) |
| `Status__c` | Current state (Active, Paused, Closed, Lapsed) |
| `StartDate__c` | When the recurring donation begins |
| `EndDate__c` | Optional end date for the commitment |
| `Planned_Installments__c` | Total expected donation count (null = indefinite) |
| `Recurring_Type__c` | Fixed (same amount) or Open (variable amount) |

## Schedule Management

The `RecurringDonationSchedule__c` object stores calculated schedules for easy opportunity lookup and forecasting:

### Schedule Records

For each recurring donation, the system generates schedule records containing:

- **Installment Number**: Sequential count (1, 2, 3, etc.)
- **Scheduled Opportunity Close Date**: When the opportunity should close
- **Planned Opportunity Amount**: Expected donation amount
- **Status**: Scheduled, Paid, Overdue, or Skipped

### Automatic Opportunity Creation

The system automatically creates opportunities on recurring donations through:

1. **Evaluation Logic**: `RD2_OpportunityEvaluation_BATCH` evaluates each recurring donation against its schedule
2. **Gap Detection**: Identifies missing opportunities between last created and next expected
3. **Bulk Creation**: Generates opportunities for all due recurring donations in a batch job
4. **Field Mapping**: Maps recurring donation fields to opportunity fields (amount, close date, stage, etc.)

### Opportunity Naming

Opportunities created from recurring donations follow a naming convention:

- Pattern: `[Donor Name] [Installment #] - [Close Date]`
- Example: `Acme Corp 5 - 2024-05-31`

## Status and State Management

### Status vs. State

The system distinguishes between:

- **Status**: User-visible state (Active, Paused, Closed, Lapsed)
- **State**: Internal tracking state for evaluation (includes intermediate values)

### Status Transitions

| From Status | To Status | Trigger |
|-------------|-----------|---------|
| Active | Paused | User action or automation |
| Active | Closed | User sets end date |
| Paused | Active | User resumes |
| Active | Lapsed | Auto-detection (e.g., no opportunity created when expected) |

### Status-to-State Mapping

The `RecurringDonationStatusMapping__mdt` custom metadata type maps user-visible statuses to internal states for opportunity creation evaluation. This allows organizations to customize which statuses should:

- Trigger automatic opportunity creation
- Prevent further opportunities
- Allow manual opportunity entry only

## Change Logging

The system provides complete audit trails through the `RecurringDonationChangeLog__c` object:

### Tracked Changes

Every modification to a recurring donation records:

- **Field Changed**: Which field was modified
- **Old Value**: Previous value
- **New Value**: New value
- **Change Type**: Create, Update, Status Change, Schedule Change
- **Timestamp**: When the change occurred

### Change Log Viewer UI

The `rd2ChangeLog` Lightning Web Component displays change history with:

- Chronological list of all changes
- Field-level detail (old value to new value)
- Change reason if provided
- User who made the change

### RD2_ChangeView Class

Server-side controller providing:

- `getChanges(Id recurringDonationId)`: Retrieves change log records
- Filtering by change type
- Formatting for display

## Recurring Donations Settings

Configuration through `Recurring_Donations_Settings__c`:

| Setting | Purpose |
|---------|---------|
| Enhanced Recurring Donations Enabled | Activates RD2 vs. legacy system |
| Change Log Enabled | Enables automatic change tracking |
| Auto-Create Opportunities | Enables automatic opportunity generation |
| Default Installment Period | Default period when creating new RD |
| Default Day of Month | Default day when creating monthly donations |
| Default Recurring Type | Fixed vs. Open commitment |
| Enable Elevate | Enables integration with Elevate payment platform |

## Advanced Features

### Commitment Service

The `RD2_CommitmentService` class provides:

- Creating new recurring donations with validation
- Updating recurring donation fields with change logging
- Calculating next expected payment date
- Validating schedules against existing opportunities

### Sustainer Status Tracking

The `RD2_SustainerEvaluationService` class automatically:

- Marks accounts/contacts with active recurring donations as "Sustainer"
- Updates sustainer status when recurring donations change
- Supports dashboard and reporting views of sustainer segments

### Custom Field Mapping

The `RD2_CustomFieldMapper` class enables:

- Mapping custom fields from opportunity to recurring donation
- Custom field sync on schedule updates
- Custom field validation

## RD2 User Interface Components

### Recurring Donation Entry Form (rd2EntryForm)

Lightning component providing:

- Create/edit recurring donation records
- Schedule preview showing next N payments
- Validation of amounts, dates, and frequencies
- Payment method selection (if Elevate enabled)

### Pause Form (rd2PauseForm)

Component for temporarily pausing recurring donations:

- Select pause start date
- Auto-resume option with resume date
- Preserves schedule integrity

### Manage Recurring Donations (rd2ManageRD)

Component for viewing active recurring donations:

- List view with key metrics
- Quick actions (pause, cancel, edit)
- Donor timeline

## Key Classes

### RD2_AppView
View model for RD2 UI providing configuration and metadata:

- Installment period options
- Frequency options with permissions
- Closed status values for opportunities
- Multi-currency settings
- Elevate customer flag
- Change log enabled flag

### RD2_Settings
Manages access to recurring donations settings with:

- Caching of setting values
- Feature flag checking
- Default value application

### RD2_SaveRequest
Request object for saving recurring donations containing:

- Recurring donation data
- Custom field values
- Change reason
- User context

### RD2_ChangeLogSelector
Query utility for retrieving change log records:

- Filter by recurring donation ID
- Sort by timestamp
- Pagination support

## Integration Points

- **Opportunities**: Recurring donations automatically create and manage opportunities
- **Contacts/Accounts**: Link to individual donors or organizations
- **Campaigns**: Opportunities can be linked to campaigns for tracking source
- **Elevate Integration**: Payment processing and reconciliation for online giving
- **Allocations**: Recurring donations support allocation of donations across funds
- **Rollups**: Recurring donation values can be rolled up to account/contact

## Use Cases

**Monthly Sustaining Donors**: Create recurring donations for monthly commitments with automatic opportunity creation every month.

**Annual Pledges**: Track multi-year commitments with opportunity creation on anniversary dates.

**Flexible Giving Programs**: Use "Open" recurring donations for variable pledge amounts, calculated each period.

**Pause and Resume**: Temporarily pause seasonal donors with automatic resume dates.

**Audit and Compliance**: Maintain complete change history for recurring donation modifications for nonprofit regulatory requirements.

**Donor Lifecycle Reporting**: Filter sustainer status to identify long-term donors for stewardship programs.
