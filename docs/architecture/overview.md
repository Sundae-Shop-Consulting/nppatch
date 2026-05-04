# Technical Overview

## Introduction

NPPatch is an enterprise-scale nonprofit package built on Salesforce using industry-standard patterns and frameworks. The architecture emphasizes maintainability, testability, and scalability through separation of concerns and configuration-driven automation.

## High-Level Architecture

NPPatch follows the Apex Enterprise Patterns (fflib) layered architecture, decomposing the application into discrete, testable tiers:

```
┌─────────────────────────────────────────────┐
│  User Interface Layer (LWC, Aura)            │
├─────────────────────────────────────────────┤
│  Controller / Adapter Layer (_CTRL, adapters) │
├─────────────────────────────────────────────┤
│  Service Layer (_SVC)                       │
├─────────────────────────────────────────────┤
│  Domain Layer (_DOM, Business Logic)        │
├─────────────────────────────────────────────┤
│  Selector Layer (_SEL, Queries)             │
├─────────────────────────────────────────────┤
│  Unit of Work (fflib_SObjectUnitOfWork)     │
├─────────────────────────────────────────────┤
│  Database Layer                             │
└─────────────────────────────────────────────┘
```

This layered approach ensures that:
- Business logic is isolated from database access code
- The same service layer methods can be reused across UI, batch jobs, and APIs
- Code is highly testable with mock implementations at each layer
- Changes to one layer don't require rewriting other layers

## TDTM Trigger Framework

All Salesforce triggers in NPPatch follow the **Table-Driven Trigger Management (TDTM)** pattern. Instead of embedding logic directly in triggers, trigger handlers are registered in the `Trigger_Handler__c` custom object, enabling:

- **Zero-Code Trigger Management**: Handlers can be enabled, disabled, or reordered without modifying code
- **Async Execution**: Individual handlers can be marked to run asynchronously
- **Consistent Error Handling**: A unified error handling framework across all triggers
- **Execution Order Control**: Handler execution order is determined by configuration, not code

### How TDTM Works

1. **Trigger Detection**: When data changes on an object, the TDTM trigger (e.g., `TDTM_Contact`) fires
2. **Configuration Lookup**: The trigger calls `TDTM_TriggerHandler.run()`, which queries `Trigger_Handler__c` records for the object
3. **Handler Instantiation**: For each matching configuration, TDTM dynamically instantiates the handler class
4. **Execution**: Handlers execute in configured order, implementing either `TDTM_Runnable` or `TDTM_RunnableMutable`
5. **DML Collection**: DML operations are queued in a `DmlWrapper` during execution
6. **Batch Processing**: All DML is executed at the end, minimizing governor limit consumption

### Key Benefits

- **Trigger handlers** are pure business logic classes with no trigger-specific code
- **Order of execution** is configurable and testable
- **Asynchronous processing** prevents transaction limits from blocking the user
- **Error handling** is consistent and doesn't require try-catch blocks in handler code
- **Testing** is straightforward: instantiate the handler class and call `run()`

## Module Structure

NPPatch organizes code into functional modules, each with a two-letter or three-letter prefix. This convention appears in class names throughout the codebase:

### Core Modules

| Prefix | Function Area | Purpose |
|--------|--------------|---------|
| **ACCT** | Account Management | Account customizations, household account processing |
| **ADDR** | Address Handling | Address creation, verification, and seasonal address management |
| **AFFL** | Affiliations | Affiliation record creation, primary affiliation tracking |
| **ALLO** | Allocations | Opportunity allocation management and campaign allocations |
| **BDI** | Batch Data Import | Data import batch processing, field mapping, matching |
| **BGE** | Batch Gift Entry | Form template management for the Gift Entry feature |
| **CAM** | Campaign | Campaign management and rollup calculations |
| **CAO** | Constants | Cross-cutting constants used throughout the system |
| **CMT** | Custom Metadata | CMT-based configuration and metadata driven patterns |
| **CON** | Contact | Contact management, household member rollups |
| **CONV** | Conversion | Conversion utilities for data transformation |
| **CRLP** | Customizable Rollups | Flexible rollup configuration and execution engine |
| **EP** | Engagement Plans | Engagement plan scheduling and task creation |
| **ERR** | Error Handling | Exception handling, error logging, notifications |
| **GAU** | General Accounting Units | Fund/cost center allocation and tracking |
| **GE** | Gift Entry | Gift entry interface and processing |
| **GS** | Get Started | Installation and post-install configuration |
| **HH** | Household | Household creation, naming, and rollup processing |
| **LD** | Leads | Lead conversion override and processing |
| **LVL** | Levels | Level configuration, evaluation, and batch assignment |
| **MTCH** | Matching | Record matching for de-duplication and merging |
| **OPP** | Opportunity | Opportunity management and related automation |
| **PMT** | Payments | Payment creation, routing, and reconciliation |
| **PSC** | Partial Soft Credit | Partial soft credit allocation and tracking |
| **RD2** | Recurring Donations | Recurring donation engine—schedules, installments, change log |
| **REL** | Relationships | Relationship record management and reciprocals |
| **STG** | Settings | Settings pages and configuration UI |
| **TEST** | Testing | Test utilities and mock implementations |
| **UTIL** | Utilities | Cross-cutting utility functions |
| **USER** | User Management | User role and permission synchronization |

### Program Management Modules

The package also includes the Program Management Module (PMM), which uses a different naming convention — full words rather than short prefixes:

| Prefix | Function Area | Purpose |
|--------|--------------|---------|
| **ServiceDelivery** | Service Delivery | Service delivery tracking, rollups, and trigger handling |
| **ServiceSchedule** | Service Scheduling | Schedule creation, session generation, domain logic |
| **ServiceSession** | Service Sessions | Session tracking, status management, attendance |
| **ServiceParticipant** | Participants | Participant enrollment and trigger handling |
| **ProgramEngagement** | Program Engagement | Participant engagement tracking and rollups |
| **Program** | Programs | Program management and selection |
| **Attendance** | Attendance | Attendance tracking UI and controller |

### Directory Organization

```
force-app/
├── nppatch-common/         # Shared infrastructure (fflib, utilities)
├── nppatch-main/
│   ├── Application.cls     # Central fflib application factory
│   ├── adapter/            # Adapter/Controller layer
│   ├── bdi/                # Batch Data Import classes
│   ├── default/
│   │   ├── classes/        # All Apex code, organized by module prefix
│   │   ├── objects/        # Custom objects and standard object extensions
│   │   ├── lwc/            # Lightning Web Components (~120)
│   │   ├── aura/           # Aura components (~46)
│   │   └── pages/          # Visualforce pages (payment wizard, utility pages)
│   ├── domain/             # Domain layer classes (_DOM)
│   ├── selector/           # Selector layer classes (_SEL)
│   ├── service/            # Service layer classes (_SVC)
│   ├── tdtm/               # TDTM trigger framework and handlers
│   └── test/               # Test utilities and factories
└── nppatch-prgm/           # Program Management Module (PMM)
    └── default/
        ├── classes/        # ~75 Apex classes (service delivery, scheduling, rollups)
        ├── objects/        # 8 custom objects (Program, Service, ServiceDelivery, etc.)
        ├── lwc/            # ~33 LWC components (attendance, scheduling, enrollment)
        └── triggers/       # 2 triggers (ServiceDelivery, ServiceParticipant)
```

## Naming Conventions

Class names follow a consistent pattern that encodes both the functional area and the architectural layer:

```
<Prefix>_<Functionality><Layer>
```

### Layer Suffixes

| Suffix | Layer | Purpose | Example |
|--------|-------|---------|---------|
| `_SVC` | Service | Orchestrates business logic, called by UI and batch | `RD2_CommitmentService` |
| `_SEL` | Selector | Encapsulates SOQL queries | `CRLP_Rollup_SEL` |
| `_DOM` | Domain | Contains object-specific business rules | `CRLP_Operation` |
| `_CTRL` | Controller | Handles UI interactions, maps to service layer | `GE_GiftEntryController` |
| `_TDTM` | Trigger Handler | Implements trigger logic via TDTM framework | `RD2_RecurringDonations_TDTM` |
| `_BATCH` | Batch Job | Implements `Database.Batchable<SObject>` | `RD2_OpportunityEvaluation_BATCH` |
| `_SCHED` | Scheduled Job | Implements `Schedulable` interface | `ADDR_Seasonal_SCHED` |
| `_TEST` | Test Class | Unit tests for production code | `RD2_ScheduleService_TEST` |
| (none) | Utility | Stateless utility functions | `UTIL_Namespace`, `CAO_Constants` |

## Infrastructure Layer (fflib)

The package includes a complete implementation of the Apex Enterprise Patterns framework:

### Application Factory

`Application.cls` is the central factory that instantiates instances of Service, Selector, UnitOfWork, and Domain classes. This supports:

- **Lazy loading** of instances
- **Dependency injection** for testing (via mock injection)
- **Type-safe factories** for each architectural layer

### Unit of Work Pattern

The `UnitOfWork` class manages DML operations in a transaction-aware manner:

- **Collects changes** without immediately persisting
- **Maintains foreign key order** to prevent constraint violations
- **Batch DML execution** reduces governor limit consumption
- **Rollback capability** via savepoint management

### Service Layer

Service classes encapsulate business logic and orchestration:

- Accept input (records, IDs, or DTOs)
- Call selectors to query data
- Invoke domain methods to enforce rules
- Register DML with UnitOfWork
- Return results or throw business exceptions

Service classes are stateless and can be reused across controllers, batch jobs, scheduled actions, and APIs.

## Settings Management

NPPatch uses a **two-tier settings architecture** for configuration:

### Custom Settings (Hierarchy)

Hierarchy custom settings support both organization-level and user-level overrides:

```apex
// Retrieve settings with user override fallback
Contacts_And_Orgs_Settings__c settings = UTIL_CustomSettingsFacade.getContactsSettings();
// Falls back to org default if no user-level setting exists
// Creates a new instance with defaults if neither exists
```

**Key Features:**
- User-level settings override org-level for personalization
- Cached in memory to avoid repeated queries
- Lazy initialization on first access
- Automatic defaults configuration via `configXxxSettings()` methods

Admins configure these settings through the **NPPatch Settings** UI (accessible from the app launcher or the NPPatch Settings tab), not through the standard Custom Settings UI in Setup.

### Custom Metadata Types (Read-Only Configuration)

Custom metadata types store configuration that should not change frequently:

- `Data_Import_Object_Mapping__mdt` — field mapping configurations
- `Data_Import_Field_Mapping__mdt` — individual field mappings
- `Rollup__mdt` — customizable rollup definitions (86 records deploy with the package)
- `Filter_Rule__mdt` — reusable filter conditions (12 records deploy with the package)
- `Filter_Group__mdt` — groups of filter rules (8 records deploy with the package)
- `Opportunity_Stage_To_State_Mapping__mdt` — recurring donation state mappings
- `RecurringDonationStatusMapping__mdt` — RD status conversion
- `GetStartedChecklistItem__mdt` — post-install checklist

Custom metadata is deployed alongside code, cached globally, queryable like regular custom objects, and version-controlled in source. Rollup definitions ship pre-populated with the package, so a fresh install has working rollups immediately.

## Error Handling

NPPatch provides a comprehensive error handling framework:

### Error Logging

The `ERR_Handler` class logs exceptions to the `Error__c` object with:
- Stack traces and error messages
- Context information (record IDs, batch numbers, class names)
- Email notifications to administrators
- Automatic log rotation

### Exception Types

Business exceptions are handled gracefully:
- Caught by TDTM framework
- User-facing error messages added to records via `addError()`
- Technical details logged for support

### Settings-Driven Control

Error handling can be configured via `Error_Settings__c`:
- Enable/disable error logging
- Configure email notifications
- Toggle debug logging

## Performance Optimization

### Batch Processing

Large operations use batch apex for:
- Recurring donation processing (`RD2_OpportunityEvaluation_BATCH`)
- Household naming and rollups (`HH_HouseholdNaming_BATCH`)
- Allocation calculations (`ALLO_MakeDefaultAllocations_BATCH`)
- Rollup field updates (`CRLP_Account_BATCH`, `CRLP_Contact_BATCH`, etc.)

### Asynchronous Execution

TDTM supports asynchronous handler execution to prevent transaction timeouts:

```apex
// In Trigger_Handler__c configuration, set Asynchronous__c = true
// Handler executes in a separate transaction
```

### Selective Trigger Execution

The framework can disable TDTM globally for data loads:

```apex
// Disable all triggers during bulk operations
TDTM_TriggerHandler.disableTDTM = true;
// ... perform bulk DML ...
TDTM_TriggerHandler.disableTDTM = false;
```

### Governor Limit Management

The Unit of Work pattern batches DML to reduce governor limit consumption:
- One INSERT, UPDATE, DELETE per object type per transaction
- Foreign key ordering prevents constraint violations
- Minimal round-trips to the database

## Testing Strategy

### fflib Mocking

The package includes `fflib_ApexMocks` for unit testing with mock implementations at each architectural layer.

### TDTM Handler Testing

Trigger handlers are tested directly without triggers:

```apex
// Test handler in isolation
CRLP_Rollup_TDTM handler = new CRLP_Rollup_TDTM();
TDTM_Runnable.DmlWrapper result = handler.run(
    newOpportunities,
    null,
    TDTM_Runnable.Action.AfterInsert,
    Schema.Opportunity.sObjectType
);
// Assert DML and side effects
```

## Key Architectural Decisions

1. **fflib over custom patterns** — Proven enterprise patterns reduce bugs and maintenance
2. **TDTM over inline triggers** — Configuration-driven automation enables easy customization
3. **Hierarchy settings with defaults** — Balances flexibility with simplicity
4. **Custom metadata for complex config** — Version-controllable, complex domain models; rollup definitions ship with the package
5. **Service-first development** — Same business logic works everywhere (UI, API, batch)
6. **Comprehensive error handling** — All errors logged and reported, never silent failures
7. **Async-capable triggers** — Large operations don't block users
8. **Testable by design** — No shared state, dependency injection, mocks throughout
9. **Single code path per feature** — Legacy fallback engines (RLLP rollups, RD1, BGE) have been removed; each feature has one implementation

---

*If you see something that could be improved, please create an issue or email admin@nppatch.com.*
