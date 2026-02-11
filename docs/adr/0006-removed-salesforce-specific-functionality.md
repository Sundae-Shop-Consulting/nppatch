# ADR-0006: Removed Salesforce-Specific Functionality

**Status:** Accepted
**Date:** 2026-02-11

## Context

The original NPSP codebase included several features that are tightly integrated with Salesforce.org's internal infrastructure and services:

1. **SfdoInstrumentation Telemetry** - Salesforce.org's internal instrumentation framework for collecting usage data
2. **LMO Telemetry (UTIL_OrgTelemetry)** - License Management Org integration for feature tracking and org telemetry
3. **SmartyStreets Address Verification** - Commercial address verification service integration
4. **Update Check System** - In-app notifications about NPSP version updates
5. **Product Update Notifications** - CustomNotificationType for pushing product announcements

These features cannot function in a community-maintained fork because:

- **No access to Salesforce.org backend services**: The telemetry endpoints, LMO infrastructure, and internal APIs are not accessible outside of Salesforce.org's managed packages
- **Commercial service dependencies**: SmartyStreets requires API keys and contracts managed by Salesforce.org
- **Package namespace conflicts**: Notification types and feature flags tied to the original NPSP namespace
- **Maintenance burden**: Keeping non-functional code paths increases complexity without benefit

## Decision

Remove all Salesforce.org-specific functionality that cannot operate independently:

### 1. SfdoInstrumentation Telemetry

**Removed:**
- All `Sfdo*` classes in `force-app/main/instrumentation/`
- Mock classes in `unpackaged/config/core_instrumentation_mock_classes/`
- All `.getInstance().log()` calls from 13 production classes

**Details:**
SfdoInstrumentation was a proprietary telemetry framework that sent usage data to Salesforce.org's internal infrastructure. The framework used a pattern of `SfdoInstrumentationService.getInstance().log()` calls throughout the codebase to track feature usage, errors, and performance metrics.

Classes that had instrumentation calls removed:
- BDI_DataImport_BATCH
- BDI_DataImportService
- BGE_DataImportBatchEntry_CTRL
- CRLP_RollupProcessor_SVC
- GE_GiftEntryController
- HH_Container_LCTRL
- HH_HouseholdNaming
- HouseholdNamingService
- HouseholdService
- RD2_OpportunityEvaluation_BATCH
- RD2_RecurringDonation
- RD2_ScheduleService
- UTIL_AuraEnabledCommon

### 2. LMO Telemetry (UTIL_OrgTelemetry)

**Removed:**
- `UTIL_OrgTelemetry.cls` and test class
- `UTIL_OrgTelemetry_BATCH.cls` and test class
- `UTIL_OrgTelemetry_SVC.cls` and test class
- `UTIL_OrgTelemetry_TDTM.cls`

**Kept:**
- `UTIL_FeatureManagement.cls` - Still used by GS_* classes and UTIL_FeatureEnablement for in-org feature flag management

**Details:**
The LMO (License Management Org) telemetry system collected org-level metrics about NPSP usage and sent them to Salesforce.org for analytics. This data was used for:
- Feature adoption tracking
- Support case correlation
- Product planning decisions

Without access to the LMO endpoint, these classes would throw errors or silently fail.

### 3. SmartyStreets Address Verification

**Removed:**
- `ADDR_SmartyStreets_Gateway.cls` and test class
- `ADDR_SmartyStreets_Validator.cls` and test class

**Kept:**
- `ADDR_Google_Validator.cls` - Uses public Google Maps API
- `ADDR_Cicero_Validator.cls` - Uses Cicero API (user-provided keys)

**Details:**
SmartyStreets is a commercial address verification service. The NPSP integration used Salesforce.org's organizational API credentials. Users of this fork can:
- Use the Google address validator (requires user's own API key)
- Use the Cicero address validator (requires user's own API key)
- Implement a custom validator using the existing interface

### 4. Update Check System

**Removed:**
- `Enable_Update_Check__c` custom setting field
- `Update_Check_Interval__c` custom setting field

**Details:**
The update check system periodically queried for new NPSP versions and displayed in-app notifications. This relied on Salesforce.org's version endpoint and is not applicable to a community fork with different versioning.

### 5. Product Update Notifications

**Removed:**
- `NPSP_Product_Updates.notiftype-meta.xml`

**Details:**
This CustomNotificationType was used to push product announcements and updates from Salesforce.org to subscriber orgs. Removing it prevents installation conflicts with orgs that have NPSP installed and avoids maintaining unused notification infrastructure.

## Consequences

### Positive

- **Cleaner codebase**: Removes dead code paths that would never execute successfully
- **Reduced maintenance burden**: No need to stub or mock unavailable services
- **Faster test execution**: Fewer classes to compile and test
- **No silent failures**: Removed code that would fail silently or throw uncaught exceptions
- **Installation compatibility**: Eliminates conflicts with existing NPSP installations (e.g., duplicate notification types)

### Negative

- **Lost telemetry capabilities**: No automatic usage tracking or error reporting
- **No address verification out of box**: Users must configure their own address verification API keys
- **No update notifications**: Users must manually check for new versions

### Mitigations

1. **Alternative telemetry**: Organizations can implement their own telemetry using:
   - Platform Events for custom event tracking
   - Custom objects for usage logging
   - Third-party APM solutions (New Relic, Datadog, etc.)

2. **Address verification**: Document how to configure Google or Cicero validators with user-provided API keys

3. **Version awareness**: Use GitHub releases, a CHANGELOG, or community communication channels for version updates

## Removed Files Summary

| Category | Files Removed | Files Kept |
|----------|---------------|------------|
| SfdoInstrumentation | ~15 classes + configs | None |
| LMO Telemetry | 7 classes | UTIL_FeatureManagement.cls |
| SmartyStreets | 4 classes | Google + Cicero validators |
| Update Check | 2 fields | None |
| Product Updates | 1 notification type | None |

## References

- completed_work.md sections 4, 8, 9, 10 for implementation details
- NPSP source code: `force-app/main/instrumentation/` (original location)
