# Recurring Donations

Recurring Donations track ongoing financial commitments from donors who give repeatedly over time. The system automates installment opportunity creation, manages payment schedules, tracks status transitions, and logs all changes for audit purposes.

## Overview

A recurring donation represents an ongoing commitment to donate at a defined frequency. Unlike single opportunities, a recurring donation automatically generates installment opportunities at the configured interval for as long as the commitment is active. Recurring donations can be linked to an individual Contact or an organization Account.

### Key Concepts

- **Recurring Donation** — a record representing an ongoing commitment to give
- **Installment Period** — the frequency at which donations occur (monthly, quarterly, annually, etc.)
- **Schedule** — the calculated dates and amounts for future installments based on the configured period and frequency
- **Donor Type** — either Account (organizational) or Contact (individual)
- **Sustainer Status** — automatic tracking of active recurring donors for engagement analysis

## Recurring Donation Fields

### Core Fields

| Field | Purpose |
|-------|---------|
| `Contact__c` / `Organization__c` | The donor—either a Contact or an Account |
| `Amount__c` | The donation amount per installment |
| `Installment_Period__c` | How often installments occur (Monthly, Quarterly, Annually, Weekly, etc.) |
| `Installment_Frequency__c` | Number of installments per period (e.g., 2 for twice a month) |
| `Day_of_Month__c` | For monthly/quarterly schedules, the day each installment falls on |
| `StartDate__c` | When the recurring donation becomes active |
| `EndDate__c` | Optional end date for the commitment |
| `Status__c` | Current state (Active, Paused, Closed, Lapsed, etc.) |
| `RecurringType__c` | Fixed (same amount each installment) or Open (variable amount) |
| `Planned_Installments__c` | Total expected installment count; null means open-ended |

### Scheduling Detail

For monthly and quarterly schedules, the `Day_of_Month__c` field controls when each installment falls. Setting this to "Last Day of Month" automatically adjusts for months with fewer days (e.g., February). The system generates a `RecurringDonationSchedule__c` record for each expected installment, providing a forward-looking schedule that drives opportunity creation and forecasting.

## Status and State Management

### Status vs. State

The system distinguishes between:

- **Status** — the user-visible field on the Recurring_Donation__c record (Active, Lapsed, Closed, Paused, etc.)
- **State** — an internal value used by the evaluation service to determine whether opportunities should be created for a given recurring donation

The `RecurringDonationStatusMapping__mdt` custom metadata type maps each status picklist value to an internal state. This allows organizations to define which statuses should trigger automatic installment creation, which should pause creation, and which should prevent any further installments.

Status mappings are configured through **NPPatch Settings > Recurring Donations > Status Mapping**.

### Status Automation

NPPatch can automatically update a recurring donation's status when no payment activity is detected for a configurable number of days. This is configured through **NPPatch Settings > Recurring Donations > Status Automation**, which exposes:

- **Days for Lapsed** — how many days of inactivity before setting the status to the lapsed value
- **Days for Closed** — how many days of inactivity before setting the status to the closed value
- **Lapsed Status Value** — which picklist value to use for lapsed
- **Closed Status Value** — which picklist value to use for closed

`RD2_StatusAutomationService` runs these checks as part of the recurring donation batch evaluation process.

## Installment Opportunity Creation

The system creates installment opportunities automatically through `RD2_OpportunityEvaluation_BATCH`, a scheduled batch job that evaluates all active recurring donations and generates opportunities for any upcoming installments that don't yet exist.

The evaluation process:

1. Loads the recurring donation's schedule (`RecurringDonationSchedule__c` records)
2. Identifies installment dates within the configured forecast window (default: 12 months)
3. Checks whether an opportunity already exists for each date using `RD2_OpportunityMatcher`
4. Creates new opportunities for any dates that don't have a match, applying the configured stage, record type, and campaign
5. Closes or deletes open opportunities for recurring donations that have been closed, following the `Open_Opportunity_Behavior__c` setting

Installment opportunities are named automatically when `EnableAutomaticNaming__c` is enabled in Recurring Donations Settings.

### First Installment Creation

The `InstallmentOppFirstCreateMode__c` setting controls whether the first installment is created synchronously (in the same transaction as the RD save) or asynchronously (queued for later processing). For most use cases, synchronous creation provides immediate feedback to the user.

## Pausing Recurring Donations

The `rd2PauseForm` Lightning component allows users to temporarily pause a recurring donation. During a pause:

- The recurring donation's status is set to the configured paused value
- The evaluation service skips installment creation for the paused period
- An optional resume date can be specified, after which the system automatically restores active status

Pause history is visible on the recurring donation record through the change log.

## Change Log

When `EnableChangeLog__c` is enabled in Recurring Donations Settings, every significant change to a recurring donation is recorded in a `RecurringDonationChangeLog__c` record. The change log captures:

- Which fields changed
- The previous and new values
- The type of change (schedule change, status change, amount change, etc.)
- When the change occurred and who made it

The `rd2ChangeLog` Lightning component displays this history on the recurring donation record page. `RD2_ChangeLogService` handles writing change log records, and `RD2_ChangeLogSelector` retrieves them for display.

## Sustainer Status Tracking

`RD2_SustainerEvaluationService` automatically marks Contacts and Accounts as sustainers based on whether they have active recurring donations. Sustainer status is recalculated when recurring donations are created, updated, or closed, and can be used to segment donors in reports and lists.

## Recurring Donation Settings

All recurring donation settings are accessible through **NPPatch Settings > Recurring Donations**. The key settings are:

| Setting | Purpose |
|---------|---------|
| `Open_Opportunity_Behavior__c` | What to do with open installment opps when an RD is closed |
| `Maximum_Donations__c` | Maximum number of installments to generate at one time |
| `Opportunity_Forecast_Months__c` | How many months forward to generate installments |
| `EnableChangeLog__c` | Whether to record change history on RD records |
| `EnableAutomaticNaming__c` | Whether to auto-name installment opportunities |
| `Record_Type__c` | Record type to use for generated installment opportunities |
| `InstallmentOppStageName__c` | Stage name for auto-created installments |

## Custom Field Mapping

`RD2_CustomFieldMapper` allows custom fields on the Recurring Donation to be mapped to corresponding fields on generated installment opportunities. This is useful for passing donor segment, fund, or campaign information through to the opportunity automatically.

## Key Classes

**`RD2_RecurringDonations_TDTM`** — the trigger handler for `Recurring_Donation__c`; delegates to the evaluation service for schedule generation and opportunity management.

**`RD2_OpportunityEvaluationService`** — core service that determines which installment opportunities need to be created, updated, or closed for a given set of recurring donations.

**`RD2_ScheduleService`** — calculates installment dates and amounts based on the recurring donation's period, frequency, and day-of-month configuration.

**`RD2_OpportunityMatcher`** — matches existing opportunities to expected installment dates to avoid duplicate creation.

**`RD2_ValidationService`** — validates recurring donation fields before save, enforcing business rules about required fields, valid date ranges, and status transitions.

**`RD2_Settings`** — wrapper around `Recurring_Donations_Settings__c` with typed accessors for all configuration fields.

**`RD2_EntryFormController`** — Apex controller for the `rd2EntryForm` Lightning component.

**`RD2_ChangeLogService`** / **`RD2_ChangeLogController`** — write and retrieve change log records.

**`RD2_StatusAutomationService`** / **`RD2_StatusAutomationSettings_CTRL`** — automate status transitions based on inactivity thresholds.

**`RD2_SustainerEvaluationService`** — evaluate and update sustainer status on related contacts and accounts.

## User Interface Components

**`rd2EntryForm`** — create and edit recurring donation records; includes schedule preview showing upcoming installments.

**`rd2PauseForm`** — temporarily pause a recurring donation with an optional auto-resume date.

**`rd2ChangeLog`** — display the full change history for a recurring donation.

**`rdScheduleVisualizer`** — visualize upcoming installment dates and amounts.

**`rd2StatusMappingSettings`** / **`rd2StatusAutomationSettings`** — configure status mappings and automation thresholds (accessed through NPPatch Settings).

## Integration Points

- **Opportunities** — recurring donations drive automatic installment opportunity creation and management
- **Contacts/Accounts** — linked as the donor; sustainer status is written back to these records
- **Campaigns** — installment opportunities can inherit the campaign from the recurring donation
- **Allocations** — recurring donation installment opportunities support allocation of amounts across funds
- **Customizable Rollups** — recurring donation values can be rolled up to Account and Contact

---

*If you see something that could be improved, please create an issue or email admin@nppatch.com.*
