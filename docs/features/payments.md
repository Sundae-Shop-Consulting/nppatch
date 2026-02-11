# Payments

The Payments feature provides detailed tracking of donation payment processing and scheduling. Organizations can record partial or full payments against opportunities, track payment status over time, manage payment refunds, and allocate payment amounts across multiple funds.

## Overview

Payments represent the financial settlement of donation opportunities. A single opportunity can have multiple payments if the donor gives in installments. The system tracks:

- **Payment Amounts**: How much was paid with each payment
- **Payment Dates**: When each payment was received
- **Payment Methods**: How payment was received (cash, check, credit card, wire, etc.)
- **Payment Status**: Outstanding, Paid, Partially Refunded, Written Off
- **Payment Allocation**: Which funds each payment supports

## Core Object: OppPayment__c

### Payment Fields

| Field | Purpose |
|-------|---------|
| `Opportunity__c` | Reference to donation opportunity |
| `Amount__c` | Payment amount |
| `Payment_Date__c` | Date payment was received |
| `Payment_Method__c` | How payment was received |
| `Status__c` | Outstanding, Paid, Refunded, Written Off |
| `Comments__c` | Notes about payment |
| `Elevate_Payment_ID__c` | ID from Elevate payment processing |
| `Payment_Posting_Date__c` | When payment posted to accounting system |

## Automatic Payment Creation

### Opportunity-to-Payment Generation

When opportunities are created or updated, the `PMT_PaymentCreator` class can automatically generate payment records:

**Scenarios for auto-creation:**

1. **Manual Opportunity Creation**: Staff creates an opportunity for a check donation
2. **Data Import**: Gift entry imports donations from external sources
3. **Recurring Donations**: Recurring donation automatically creates opportunities, which auto-create payments

### Payment Amount Handling

- **Full Payment**: Single opportunity creates one payment for the full amount
- **Partial Payment**: Opportunity can have multiple payments totaling to amount
- **Overpayment**: Multiple payments can exceed opportunity amount (rare, typically error)
- **Underpayment**: Opportunity can remain partially unpaid

### Auto-Creation Settings

Configuration through `Payments_Settings__c` controls:

| Setting | Effect |
|---------|--------|
| Payments Enabled | Activates payment feature |
| Auto-Create Payments | Whether opportunities auto-generate payment records |
| Default Payment Method | Default method for auto-created payments |
| Payment Posting Delay | Days before payment auto-posts to accounting |

## Payment Status Management

### Status Lifecycle

Payments follow a status progression:

```
Outstanding (created)
    ↓
Paid (payment received)
    ↓
[Optional: Refunded, Written Off]
```

### Status Definitions

| Status | Meaning | Further Changes |
|--------|---------|-----------------|
| Outstanding | Payment expected but not received | Can mark Paid, Written Off |
| Paid | Payment received and posted | Can Refund or Write Off |
| Partially Refunded | Partial refund issued | Can refund more or write off balance |
| Written Off | Amount will not be collected | Terminal (no further changes) |
| Refunded | Full refund issued | Terminal (no further changes) |

### Payment Status Updates

Users can manually update payment status through the OppPayment__c record or UI:

1. **Mark as Paid**: Change status from Outstanding to Paid with payment date
2. **Write Off**: Change to Written Off with explanation
3. **Refund**: Initiate refund process (see Refunds section)

## Payment Scheduling

### Multi-Payment Scenarios

For pledges or installment commitments:

1. Create opportunity with full commitment amount
2. Create multiple payment records with scheduled dates and amounts
3. Each payment triggers reminder as due date approaches
4. Mark payments as received once collected

**Example: $5,000 annual pledge paid quarterly**

```
Payment 1: $1,250, due 2024-03-31, status Outstanding
Payment 2: $1,250, due 2024-06-30, status Outstanding
Payment 3: $1,250, due 2024-09-30, status Outstanding
Payment 4: $1,250, due 2024-12-31, status Outstanding
```

### Expected vs. Actual

The system supports tracking:

- **Expected Payment Date**: When payment was expected
- **Payment Date**: When payment actually received
- **Aging**: How many days overdue (expected date vs. today)

## Payment Write-Offs

### Write-Off Logic

When a payment is written off:

1. Status changes to "Written Off"
2. Amount is no longer considered collectable
3. Opportunity remaining amount adjusts
4. Write-off can be reversed if collected later

### Write-Off Scenarios

Common write-off reasons:

- Donor deceased or moved with no contact
- Bad check that cannot be reclaimed
- Donor bankruptcy or insolvency
- Amount too small to pursue collection
- Donor dispute/cancellation

## Refund Support

### PMT_RefundController

Server-side controller managing refund processing:

```apex
RefundView refundView = PMT_RefundController.getInitialView(paymentId);
RefundView result = PMT_RefundController.processRefund(paymentId, refundAmount);
```

### Refund Process

1. **Check Refundability**: Verify payment can be refunded (not already refunded, not written off)
2. **Calculate Amount**: Allow full or partial refund
3. **Process Refund**:
   - If Elevate payment: Call Elevate API
   - If manual payment: Create refund record noting the reversal
4. **Update Status**: Change payment status to Refunded or Partially Refunded
5. **Adjust Opportunity**: Reduce opportunity amount if applicable

### Refund Information

`PMT_RefundService.RefundInfo` tracks:

- Original payment details
- Remaining refundable balance
- Elevate payment ID (if from payment processor)
- Refund eligibility (within refund window, valid payment type, etc.)

### Elevate Refunds

For payments processed through Elevate:

1. **Retrieve Payment**: Get Elevate payment details
2. **Check Refund Window**: Elevate has time limits on refunds (typically 90 days)
3. **Call Elevate API**: Process refund through Elevate system
4. **Update Payment**: Mark refund status and sync back to Salesforce

## Payment Allocation

### Allocation Integration

Payments can be allocated across General Accounting Units (GAUs/funds):

- **Opportunity-Level Allocation**: Spread across funds at donation level
- **Payment-Level Allocation**: Different funds can receive installments
- **Allocation Status**: Tracks allocated vs. actually paid

### Payment to Allocation Mapping

When payment is recorded:

1. Look up related opportunity allocations
2. Calculate proportion of opportunity payment represents
3. Create or update payment allocations with same proportions
4. Update GAU allocation status (Allocated → Paid)

## Payment Field Mapping from Data Import

### BDI Payment Field Support

The Data Import engine maps these DataImport fields to OppPayment__c:

| DataImport Field | OppPayment Field | Purpose |
|------------------|-----------------|---------|
| `Payment_Amount__c` | `Amount__c` | Payment amount |
| `Payment_Date__c` | `Payment_Date__c` | When paid |
| `Payment_Method__c` | `Payment_Method__c` | How paid |

### Payment Creation During Import

When DataImport__c is processed:

1. Check if Payments enabled
2. If `Payment_Amount__c` is populated, create payment record
3. Map data import payment fields to OppPayment__c fields
4. Link payment to created opportunity
5. Mark opportunity as fully or partially paid

## Payment Validation

### PMT_ValidationService

Validates payments before saving:

| Validation | Rule |
|-----------|------|
| Amount > 0 | Payment amount must be positive |
| Status Valid | Status must be from valid picklist |
| Payment Date | Date should not be in far future |
| Amount ≤ Opportunity | Sum of payments shouldn't exceed opp amount |
| Refund Amount | Refund amount ≤ payment amount |

### Validation Errors

Common validation failures:

- Payment amount is negative
- Payment amount exceeds opportunity amount
- Payment date is invalid or missing
- Attempt to refund already-refunded payment
- Attempt to pay fully refunded payment

## Payment Settings

### Payments_Settings__c

Organization-wide payment configuration:

| Setting | Purpose |
|---------|---------|
| Payments Enabled | Activates payment tracking |
| Auto-Create Payments | Auto-create for all opportunities |
| Default Payment Method | Default method for auto-payments |
| Payment Posted Days | Days before auto-posting to GL |
| Write-Off Reason Options | Picklist values for write-off reasons |
| Refund Window Days | Days after payment when refund allowed |
| Enable Elevate Refunds | Allow refunds through Elevate |

## Integration with Elevate

### Elevate Payment Processing

For organizations using Elevate payment platform:

1. **Payment Creation**: Elevate generates OppPayment__c records
2. **Elevate ID**: `Elevate_Payment_ID__c` links to Elevate system
3. **Sync Status**: Payment status syncs with Elevate (pending, settled, failed)
4. **Refunds**: Refunds processed through Elevate API
5. **Reconciliation**: Regular sync ensures Salesforce matches Elevate

### PS_GatewayService

Elevate payment gateway integration:

- Retrieves payment status from Elevate
- Processes refunds through Elevate
- Handles payment failures and retries
- Syncs transaction fees and statuses

## Payment Views and Reporting

### Payment Related List

On opportunity records, shows all related payments:

- Amount, date, status
- Payment method
- Refund history
- Quick actions (mark paid, refund, write off)

### Payment Aging Report

Common reporting use case:

- List outstanding payments by aging bucket
- Show days overdue
- Segment by payment method
- Display donor contact info for collection

### Cash Application

Finance staff use payments to:

- Reconcile bank deposits to donations
- Match checks/wires to donors
- Apply unidentified cash to appropriate opportunities
- Track uncollectable amounts

## Key Classes

### PMT_PaymentCreator

Creates payment records from opportunities:

- Auto-creates on opportunity insert/update
- Calculates payment date from opportunity close date
- Sets status to Outstanding for created payments
- Respects payment enablement settings

### PMT_RefundController

LWC controller for refund UI:

- `getInitialView()`: Load refund details
- `processRefund()`: Execute refund
- Elevate integration for payment processor refunds

### PMT_ValidationService

Validates payment records before save:

- Amount validation
- Status logic
- Refund eligibility
- Integration with Elevate if enabled

### PMT_CascadeDeleteLookups_TDTM

Trigger handler managing payment deletion:

- When opportunity deleted, handle related payments
- Prevents orphaned payment records
- Triggers cleanup of related records

## Integration Points

- **Opportunities**: Payments settle opportunities
- **Allocations**: Payments split across funds/GAUs
- **Data Import**: Payment data comes from external sources
- **Recurring Donations**: Auto-create payments for installments
- **Elevate**: Payment processing and refund integration
- **Reporting**: Finance reports on cash received and aging

## Use Cases

**Pledge Tracking**: Record donation as opportunity, create multiple payment records for quarterly installments, mark payments received as checks arrive.

**Refund Processing**: Customer requests refund of credit card donation within 90 days, process refund through Elevate gateway automatically.

**Bad Check Handling**: Check bounces, mark payment as Written Off with reason "Bad Check", flag for donor communication.

**Multi-Fund Giving**: Donor gives $1,000 with 40% to Program and 60% to Operations, allocations on payment split appropriately.

**Cash Receipting**: Finance receives bank deposit list, create payments for unmatched deposits, match to opportunities, apply to correct donors.

**Partial Payments**: Grant funder promises $50,000, create payment for initial $25,000 received, schedule second payment when balance expected.

---

*This documentation was generated by AI and still needs human review. If you see something that could be improved, please create an issue or email admin@nppatch.com.*
