# Technical Overview

## Introduction

nppatch is an enterprise-scale nonprofit package built on Salesforce using industry-standard patterns and frameworks. The architecture emphasizes maintainability, testability, and scalability through separation of concerns and configuration-driven automation.

## High-Level Architecture

nppatch follows the Apex Enterprise Patterns (fflib) layered architecture, decomposing the application into discrete, testable tiers:

```
┌─────────────────────────────────────────────┐
│  User Interface Layer (LWC, Aura, VF)       │
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

All Salesforce triggers in nppatch follow the **Table-Driven Trigger Management (TDTM)** pattern. Instead of embedding logic directly in triggers, trigger handlers are registered in the `Trigger_Handler__c` custom object, enabling:

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

nppatch organizes code into functional modules, each with a two-letter or three-letter prefix. This convention appears in class names throughout the codebase:

### Core Modules

| Prefix | Function Area | Purpose |
|--------|--------------|---------|
| **ACCT** | Account Management | Account customizations, household account processing |
| **ADDR** | Address Handling | Address creation, verification, and seasonal address management |
| **AFFL** | Affiliations | Affiliation record creation, primary affiliation tracking |
| **ALLO** | Allocations | Opportunity allocation management and campaign allocations |
| **BDE** | Batch Data Entry | Batch donation entry user interface and validation |
| **BDI** | Batch Data Import | Data import batch processing, field mapping, matching |
| **BGE** | Batch Gift Entry | Gift entry batch creation and processing |
| **CAM** | Campaign | Campaign management and rollup calculations |
| **CAO** | Constants | Cross-cutting constants used throughout the system |
| **CMT** | Custom Metadata | CMT-based configuration and metadata driven patterns |
| **CON** | Contact | Contact management, household member rollups |
| **CONV** | Conversion | Conversion utilities for data transformation |
| **CRLP** | Customizable Rollups | Flexible rollup configuration and execution engine |
| **EP** | Engagement Plans | Engagement plan scheduling and task creation |
| **ERR** | Error Handling | Exception handling, error logging, notifications |
| **GAU** | General Accounting Units | Fund/cost center allocation and tracking |
| **GE** | Gift Entry | Modern gift entry interface and processing |
| **GS** | Get Started | Installation and post-install configuration |
| **HH** | Household | Household creation, naming, and rollup processing |
| **LD** | Levels | Level assignment and batch processing |
| **LVL** | Levels | Level configuration and evaluation |
| **MTCH** | Matching | Record matching for de-duplication and merging |
| **OPP** | Opportunity | Opportunity management and related automation |
| **PMT** | Payments | Payment creation, routing, and reconciliation |
| **PSC** | Partial Soft Credit | Partial soft credit allocation and tracking |
| **RD** | Recurring Donations (v1) | Legacy recurring donation processing |
| **RD2** | Recurring Donations (v2) | Next-generation recurring donation engine |
| **REL** | Relationships | Relationship record management and reciprocals |
| **RLLP** | Rollup | Rollup field synchronization and updates |
| **STG** | Settings | Settings pages and configuration UI |
| **TEST** | Testing | Test utilities and mock implementations |
| **UTIL** | Utilities | Cross-cutting utility functions |
| **USER** | User Management | User role and permission synchronization |

### Directory Organization

```
force-app/
├── infrastructure/
│   ├── apex-common/        # fflib base classes and foundation
│   ├── apex-extensions/    # fflib extensions specific to nppatch
│   └── apex-mocks/         # fflib mocking framework for testing
├── main/
│   ├── default/
│   │   ├── classes/        # All Apex code, organized by module prefix
│   │   ├── objects/        # Custom objects and standard object extensions
│   │   ├── triggers/       # Visualforce pages and components (legacy)
│   │   └── lwc/            # Lightning Web Components
│   ├── service/            # Service layer classes (_SVC)
│   ├── selector/           # Selector layer classes (_SEL)
│   ├── domain/             # Domain layer classes (_DOM)
│   └── adapter/            # Adapter/Controller layer
└── tdtm/
    ├── triggers/           # TDTM trigger handlers (one per object)
    ├── classes/            # TDTM framework classes
    ├── objects/            # Trigger_Handler__c and related objects
    └── triggerHandlers/    # Individual trigger handler implementations
```

## Naming Conventions

Class names follow a consistent pattern that encodes both the functional area and the architectural layer:

```
<Prefix>_<Functionality><Layer>
```

### Layer Suffixes

| Suffix | Layer | Purpose | Example |
|--------|-------|---------|---------|
| `_SVC` | Service | Orchestrates business logic, called by UI and batch | `OPP_OpportunityCloneService_SVC` |
| `_SEL` | Selector | Encapsulates SOQL queries | `OPP_OpportunitySelector_SEL` |
| `_DOM` | Domain | Contains object-specific business rules | `OPP_OpportunitiesDomain_DOM` |
| `_CTRL` | Controller | Handles UI interactions, maps to service layer | `GE_GiftEntry_CTRL` |
| `_TDTM` | Trigger Handler | Implements trigger logic via TDTM framework | `OPP_OpportunityAfterUpdate_TDTM` |
| `_BATCH` | Batch Job | Implements `Database.Batchable<SObject>` | `RD2_RecurringDonationBatch_BATCH` |
| `_SCHED` | Scheduled Job | Implements `Schedulable` interface | `HH_HouseholdNaming_SCHED` |
| `_TEST` | Test Class | Unit tests for production code | `OPP_OpportunityCloneService_TEST` |
| (none) | Utility | Stateless utility functions | `UTIL_Namespace`, `CAO_Constants` |

### Examples

- `OPP_OpportunityBeforeInsert_TDTM` - Trigger handler for Opportunity before insert
- `RD2_RecurringDonationSchedule_SVC` - Service for recurring donation scheduling
- `CRLP_RollupCalculation_SEL` - Selector for rollup field queries
- `HH_HouseholdProcessing_DOM` - Domain logic for household operations

## Infrastructure Layer (fflib)

The package includes a complete implementation of the Apex Enterprise Patterns framework:

### fflib_Application

The central application factory that instantiates instances of Service, Selector, UnitOfWork, and Domain classes. This supports:

- **Lazy loading** of instances
- **Dependency injection** for testing (via mock injection)
- **Type-safe factories** for each architectural layer

```apex
// Service layer usage
OPP_OpportunitySvc_SVC svc = (OPP_OpportunitySvc_SVC) fflib_Application.Service.newInstance(OPP_IOpportunitySvc_SVC.class);
svc.processOpportunities(opportunities);

// Selector layer usage
OPP_OpportunitySel_SEL sel = (OPP_OpportunitySel_SEL) fflib_Application.Selector.newInstance(OPP_IOpportunitySel_SEL.class);
List<Opportunity> opps = sel.selectById(opportunityIds);

// Unit of Work usage
fflib_ISObjectUnitOfWork uow = fflib_Application.UnitOfWork.newInstance();
uow.registerNew(newRecord);
uow.commitWork();
```

### Unit of Work Pattern

The `fflib_SObjectUnitOfWork` manages DML operations in a transaction-aware manner:

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

nppatch uses a **two-tier settings architecture** for configuration:

### Custom Settings (Hierarchy)

Hierarchy custom settings support both organization-level and user-level overrides:

```apex
// Retrieve settings with user override fallback
Contacts_And_Orgs_Settings__c settings = UTIL_CustomSettingsFacade.getContactsSettings();

// If not exists at user level, falls back to org default
// If not exists anywhere, creates empty instance with defaults
```

**Key Features:**
- User-level settings override org-level for personalization
- Cached in memory to avoid repeated queries
- Lazy initialization on first access
- Automatic defaults configuration via `configXxxSettings()` methods

### Custom Metadata Types (Read-Only Configuration)

Custom metadata types store configuration that should not change frequently:

- **Data_Import_Object_Mapping__mdt** - Field mapping configurations
- **Data_Import_Field_Mapping__mdt** - Individual field mappings
- **Rollup__mdt** - Customizable rollup definitions
- **Filter_Rule__mdt** - Reusable filter conditions
- **Opportunity_Stage_To_State_Mapping__mdt** - Recurring donation state mappings
- **GetStartedChecklistItem__mdt** - Post-install checklist
- And 6+ others

Custom metadata is:
- Deployed alongside code
- Cached globally (not per-user)
- Queryable like regular custom objects
- Version-controlled in source

## Error Handling

nppatch provides a comprehensive error handling framework:

### Error Logging

The `ERR_Handler` class logs exceptions to the `Error__c` object with:
- Stack traces and error messages
- Context information (record IDs, batch numbers, class names)
- Email notifications to administrators
- Automatic log rotation

### Exception Types

```apex
public class fflib_Application {
    public class ApplicationException extends Exception { }
    public class DeveloperException extends Exception { }
}
```

Business exceptions are handled gracefully:
- Caught by TDTM framework
- User-facing error messages added to records via `addError()`
- Technical details logged for support

### Settings-Driven Control

Error handling can be configured via `Error_Settings__c`:
- Enable/disable error logging
- Configure email notifications
- Toggle debug logging
- Enable override feature pilots

## Performance Optimization

### Batch Processing

Large operations use batch apex for:
- Recurring donation processing (RD2_RecurringDonationBatch)
- Household naming and rollups
- Allocation calculations
- Rollup field updates

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

The package includes `fflib_ApexMocks` for unit testing:

```apex
// Create mock implementations
fflib_ApexMocks mocks = new fflib_ApexMocks();
OPP_IOpportunitySel_SEL mockSelector = (OPP_IOpportunitySel_SEL) mocks.mock(OPP_IOpportunitySel_SEL.class);

// Configure mock behavior
mocks.startStubbing();
mocks.when(mockSelector.selectById(opportunityIds)).thenReturn(mockOpportunities);
mocks.stopStubbing();

// Inject mock
fflib_Application.Selector.setMock(mockSelector);

// Execute and verify
```

### TDTM Handler Testing

Trigger handlers are tested directly without triggers:

```apex
// Test handler in isolation
OPP_OpportunityBeforeInsert_TDTM handler = new OPP_OpportunityBeforeInsert_TDTM();
TDTM_Runnable.DmlWrapper result = handler.run(
    newOpportunities,
    null,  // oldList
    TDTM_Runnable.Action.BeforeInsert,
    Schema.Opportunity.sObjectType
);

// Assert DML and side effects
```

## Deployment Architecture

### Package Structure

nppatch is deployed as a managed package with:
- Core functionality in the managed namespace
- Extensibility points for customer customizations
- Configuration-first approach minimizing custom code needs

### Namespace Isolation

When installed as a managed package:
- Prefix namespace references: `nppatch__CustomField__c`
- Utility functions handle namespace transparency: `UTIL_Namespace.StrTokenNSPrefix()`
- Tests run in both managed and unmanaged contexts

## Key Architectural Decisions

1. **fflib over custom patterns** - Proven enterprise patterns reduce bugs and maintenance
2. **TDTM over inline triggers** - Configuration-driven automation enables easy customization
3. **Hierarchy settings with defaults** - Balances flexibility with simplicity
4. **Custom metadata for complex config** - Version-controllable, complex domain models
5. **Service-first development** - Same business logic works everywhere (UI, API, batch)
6. **Comprehensive error handling** - All errors logged and reported, never silent failures
7. **Async-capable triggers** - Large operations don't block users
8. **Testable by design** - No shared state, dependency injection, mocks throughout
