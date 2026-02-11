# ADR-0003: Configure Valid Stages in Test Setup

**Status:** Accepted
**Date:** 2026-02-10

## Context

Many NPSP tests hardcoded the "Pledged" stage name when creating Opportunities, either directly or through RD2 (Recurring Donations) functionality. The custom label `RecurringDonationStageName` also defaults to "Pledged".

In 2GP scratch orgs used for package version creation:
- "Pledged" is not a standard Salesforce stage
- We cannot add custom stages to StandardValueSet (per ADR-0001)
- Tests fail when trying to create Opportunities with invalid stage values

Options considered:
1. Change the custom label default to a standard stage
2. Configure valid stages in test setup
3. Skip affected tests in 2GP context

## Decision

Configure valid stages explicitly in test setup rather than changing production defaults.

**Pattern for RD2 tests:**
```apex
String openStage = UTIL_UnitTestData_TEST.getOpenStage();
RD2_Settings_TEST.setUpConfiguration(new Map<String, Object>{
    'InstallmentOppStageName__c' => openStage
});
RD2_EnablementService_TEST.setRecurringDonations2Enabled();
```

**Pattern for other tests creating Opportunities:**
```apex
// Instead of:
StageName = 'Pledged'

// Use:
StageName = UTIL_UnitTestData_TEST.getOpenStage()
```

## Consequences

### Positive
- Production UX unchanged (label still says "Pledged" for existing users)
- Tests work in any org configuration
- No dependency on specific stage values existing
- Tests are more portable and robust

### Negative
- More verbose test setup
- Must remember to configure stage in new tests
- Existing tests need updates

### Files Modified
- `PMT_PaymentWizard_TEST.cls` - Use `getOpenStage()` in helper method
- `RD2_OpportunityService_TEST.cls` - Lazy-init stage constants
- `GiftEntryProcessorQueue_TEST.cls` - Add stage configuration
- `RD2_OpportunityEvaluationService_TEST.cls` - Add stage configuration

## Related
- ADR-0001: Standard Stages for Business Processes
- `UTIL_UnitTestData_TEST.getOpenStage()` - Queries for any valid open stage
