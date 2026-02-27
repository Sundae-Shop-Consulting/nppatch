# Payments

The Payments feature tracks donation payment processing and scheduling. Organizations can record partial or full payments against opportunities, track payment status over time, manage refunds, and allocate payment amounts across multiple funds.

## Overview

Payments represent the financial settlement of donation opportunities. A single opportunity can have one or multiple payments, supporting installment-based giving. The system tracks:

- **Payment Amounts**: How much was paid with each payment
- **Payment Dates**: When each payment was received
- **Payment Methods**: How payment was received (cash, check, credit card, wire, etc.)
- **Payment Status**: Outstanding, Paid, Written Off
- **Payment Allocation**: Which funds each payment supports (when Allocations are enabled)

## Core Object: OppPayment__c

### Payment Fields

| Field | Purpose |
|-------|---------|
| `Opportunity__c` | Reference to the parent donation opportunity |
| `Amount__c` | Payment amount |
| `Payment_Date__c` | Date payment was received |
| `Payment_Method__c` | How payment was received |
| `Paid__c` | Boolean indicating whether the payment has been received |
| `Written_Off__c` | Boolean indicating whether the payment was written off |
| `Comments__c` | Notes about the payment |
| `Payment_Posting_Date__c` | When payment posted to accounting system |
| `Scheduled_Date__c` | When payment was expected |

## Automatic Payment Creation

### Opportunity-to-Payment Generation

When opportunities are created or updated, the `PMT_PaymentCreator` class can automatically generate payment records. This behavior is controlled by the `Payments_Enabled__c` field in `Contacts_And_Orgs_Settings__c`.

**Scenarios for auto-creation:**

1. **Manual Opportunity Creation**: Staff creates an opportunity for a check donation — a single payment record is generated
2. **Data Import**: Gift Entry imports donations from external sources — payment records are created during import processing
3. **Recurring Donations**: The recurring donation engine creates installment opportunities, each of which auto-creates a payment

### Payment Amount Handling

- **Full Payment**: Single opportunity creates one payment for the full amount
- **Partial Payment**: An opportunity can have multiple payments totaling to the amount
- **Overpayment**: Multiple payments can exceed the opportunity amount (rare, typically an error)
- **Underpayment**: An opportunity can remain partially unpaid

### Auto-Creation Settings

Payment creation is configured through `Contacts_And_Orgs_Settings__c`:

| Setting | Effect |
|---------|--------|
| `Payments_Enabled__c` | Activates payment feature — when enabled, payment records are automatically created for new opportunities |
| `Opp_RecTypes_Excluded_for_Payments__c` | Semicolon-separated record type names excluded from automatic payment creation |
| `Opp_Types_Excluded_for_Payments__c` | Semicolon-separated opportunity types excluded from automatic payment creation |
| `Payments_Auto_Close_Stage_Name__c` | Stage name to set on opportunities when all payments are marked as paid |

Configure these in **NPPatch Settings > Donations > Payments**.

## Payment Status Management

### Status Lifecycle

Payments follow a status progression:

```
Outstanding (created)
    ↓
Paid (payment received)
    ↓
[Optional: Written Off]
```

### Status Definitions

| Status | Meaning | Further Changes |
|--------|---------|-----------------|
| Outstanding | Payment expected but not received | Can mark Paid or Written Off |
| Paid | Payment received and posted | Can write off |
| Written Off | Amount will not be collected | Terminal |

### Payment Status Updates

Users update payment status through the OppPayment__c record:

1. **Mark as Paid**: Set `Paid__c = true` and populate `Payment_Date__c`
2. **Write Off**: Set `Written_Off__c = true` with an explanation in Comments

When all payments on an opportunity are marked as Paid, the opportunity can be automatically advanced to the stage specified in `Payments_Auto_Close_Stage_Name__c`.

## Payment Scheduling

### Multi-Payment Scenarios

For pledges or installment commitments:

1. Create an opportunity with the full commitment amount
2. Create multiple payment records with scheduled dates and amounts
3. Mark payments as received once collected

**Example: $5,000 annual pledge paid quarterly**

```
Payment 1: $1,250, scheduled 2025-03-31, status Outstanding
Payment 2: $1,250, scheduled 2025-06-30, status Outstanding
Payment 3: $1,250, scheduled 2025-09-30, status Outstanding
Payment 4: $1,250, scheduled 2025-12-31, status Outstanding
```

### Payment Wizard

The `PMT_PaymentWizard` Visualforce page provides a UI for creating payment schedules. Users specify the number of installments, the start date, and the interval, and the wizard generates the corresponding payment records.

## Payment Write-Offs

### Write-Off Logic

When a payment is written off:

1. `Written_Off__c` is set to `true`
2. The amount is no longer considered collectable
3. The opportunity's remaining balance adjusts accordingly

### Write-Off Scenarios

Common write-off reasons:

- Donor deceased or moved with no contact
- Bad check that cannot be reclaimed
- Donor dispute or cancellation
- Amount too small to pursue collection

## Refund Support

### PMT_RefundController

The `PMT_RefundController` class provides server-side refund processing for the refund Lightning component:

```apex
RefundView refundView = PMT_RefundController.getInitialView(paymentId);
RefundView result = PMT_RefundController.processRefund(paymentId, refundAmount);
```

### Refund Process

1. **Check Refundability**: Verify the payment can be refunded (has been paid, not already fully refunded)
2. **Calculate Amount**: Allow full or partial refund
3. **Create Refund Record**: Create a new negative-amount payment record representing the refund
4. **Update Status**: Adjust the original payment record

## Payment Allocation

### Allocation Integration

When Allocations are enabled (`Allocations_Settings__c`), payments can be allocated across General Accounting Units (GAUs/funds):

- **Opportunity-Level Allocation**: Spread across funds at the donation level
- **Payment-Level Allocation**: Different funds can receive different installments

### Payment to Allocation Mapping

When a payment is recorded:

1. Look up related opportunity allocations
2. Calculate the proportion of the opportunity this payment represents
3. Create or update payment allocations with the same proportions

## Payment Field Mapping from Data Import

### BDI Payment Field Support

The Data Import engine maps these `DataImport__c` fields to `OppPayment__c`:

| DataImport Field | OppPayment Field | Purpose |
|------------------|-----------------|---------|
| `Payment_Amount__c` | `Amount__c` | Payment amount |
| `Payment_Date__c` | `Payment_Date__c` | When paid |
| `Payment_Method__c` | `Payment_Method__c` | How paid |

### Payment Creation During Import

When a `DataImport__c` record is processed:

1. Check if Payments are enabled
2. If `Payment_Amount__c` is populated, create a payment record
3. Map data import payment fields to `OppPayment__c` fields
4. Link the payment to the created opportunity

## Payment Validation

### PMT_ValidationService

Validates payments before saving:

| Validation | Rule |
|-----------|------|
| Amount > 0 | Payment amount must be positive |
| Status Valid | Status must be from a valid picklist value |
| Payment Date | Date should not be in the far future |
| Amount ≤ Opportunity | Sum of payments should not exceed opportunity amount |

## Payment Field Mapping Settings

`Payment_Field_Mapping_Settings__c` is a list custom setting that allows organizations to define custom field mappings between Opportunity and OppPayment__c. When payments are auto-created, the mapped fields are copied from the parent Opportunity to the new payment record.

The payment field mapping UI is accessible through **NPPatch Settings > Donations > Payment Mapping**. The `STG_PanelPaymentMapping_CTRL` controller manages this configuration.

## Key Classes

**`PMT_PaymentCreator`** — Creates payment records from opportunities. Auto-creates on opportunity insert/update, calculates payment dates from the opportunity close date, and sets initial status to Outstanding.

**`PMT_RefundController`** — LWC controller for the refund UI. Provides `getInitialView()` to load refund details and `processRefund()` to execute refunds.

**`PMT_ValidationService`** — Validates payment records before save, including amount validation, status logic, and refund eligibility checks.

**`PMT_Payment_TDTM`** — Trigger handler managing payment lifecycle events including validation, opportunity amount syncing, and cascade operations.

**`PMT_PaymentWizard_CTRL`** — Controller for the payment scheduling wizard Visualforce page.

## Integration Points

- **Opportunities**: Payments settle opportunities — when all payments are received, the opportunity can auto-close
- **Allocations**: Payments can be split across funds/GAUs when Allocations are enabled
- **Data Import**: Payment data flows through the Gift Entry / Data Import engine
- **Recurring Donations**: Installment opportunities auto-create payment records
- **Customizable Rollups**: Payment-level rollups can aggregate to Account and Contact

## Use Cases

**Pledge Tracking**: Record a donation commitment as an opportunity, create multiple payment records for quarterly installments, and mark payments as received when checks arrive.

**Bad Check Handling**: A check bounces — mark the payment as Written Off with reason "Bad Check" and flag the donor for communication.

**Multi-Fund Giving**: A donor gives $1,000 with 40% to Program and 60% to Operations. When Allocations are enabled, the allocations on the payment split accordingly.

**Cash Receipting**: Finance receives a bank deposit list, creates payments for unmatched deposits, and matches them to the correct opportunities and donors.

**Partial Payments**: A grant funder promises $50,000. Create a payment for the initial $25,000 received and schedule a second payment when the balance is expected.

---

*If you see something that could be improved, please create an issue or email admin@nppatch.com.*
