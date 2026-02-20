# ADR-0007: Multi-Package Architecture with nppatch-common

**Status:** Accepted
**Date:** 2026-02-20

## Context

As the NPPatch codebase grows, foundational infrastructure (fflib, TDTM framework, utility classes) is tightly coupled with domain-specific business logic in a single `force-app` package. This creates several problems:

- **Compilation coupling**: All Apex compiles together, so a bug in any domain class can cascade failures across unrelated components.
- **Deployment rigidity**: Infrastructure changes require redeploying the entire package.
- **Unclear boundaries**: No enforcement of dependency direction between framework code and business logic.
- **Package size**: A single large package is slower to build, validate, and deploy.

The TDTM (Table-Driven Trigger Management) framework is a key example. It provides base classes (`TDTM_Runnable`, `TDTM_RunnableMutable`), configuration (`TDTM_DefaultConfig`, `Trigger_Handler__c`), and process control (`TDTM_ProcessControl`) that all trigger handlers depend on. These framework types have no inherent dependency on domain logic, yet they lived alongside the handlers that extend them.

## Decision

Split the codebase into two unlocked packages sharing the `nppatch` namespace:

1. **nppatch-common** (`force-app-common/`): Foundational infrastructure with no domain dependencies.
2. **nppatch** (`force-app/`): Domain-specific business logic that depends on nppatch-common.

### Package contents

**nppatch-common** contains:
- `infrastructure/` — fflib framework (apex-common, apex-extensions, apex-mocks)
- `utilities/` — Foundational utility classes (UTIL_Describe, UTIL_Namespace, UTIL_IntegrationGateway, ErrorRecord, etc.)
- `tdtm/` — TDTM framework classes (TDTM_Runnable, TDTM_RunnableMutable, TDTM_DefaultConfig, TDTM_ProcessControl, TDTM_TriggerActionHelper, TDTM_iTableDataGateway) and Trigger_Handler__c metadata

**nppatch** contains:
- All domain-specific Apex (trigger handlers, services, domain classes)
- TDTM orchestration classes that bridge framework and domain (TDTM_Config_API, TDTM_TriggerHandler, TDTM_ObjectDataGateway)
- All triggers, custom objects (except Trigger_Handler__c), LWC, VF pages, etc.

### Dependency direction

```
nppatch-common  <──  nppatch
(infrastructure)     (domain logic)
```

`nppatch-common` has zero dependencies. `nppatch` depends on `nppatch-common`. Code in `force-app-common` must never reference classes or objects in `force-app`.

### Key refactoring decisions

Two cross-package dependencies were discovered and resolved:

1. **TDTM_Runnable.runFuture()** referenced `TDTM_TriggerHandler.processDML()` (a force-app class). Resolution: Moved `runFuture()` and `runFutureNonStatic()` to `TDTM_TriggerHandler`, since TriggerHandler was already the sole caller.

2. **TDTM_ProcessControl.toggleTriggerState()** referenced `TDTM_Config_API.getCachedRecords()` (a force-app class). Resolution: Moved `toggleTriggerState()` to `TDTM_Config_API`, where it is thematically aligned with the other trigger configuration methods.

### Classes that could not move

- **TDTM_Config_API** — The main TDTM orchestrator. References `TDTM_ObjectDataGateway` and `TDTM_TriggerHandler` extensively. Acts as the bridge between framework types (common) and runtime implementations (force-app).
- **TDTM_TriggerHandler** — The trigger dispatch engine. Depends on `ERR_Handler`, `ERR_ExceptionHandler`, `UTIL_DMLService`, `UTIL_Debug`.
- **TDTM_ObjectDataGateway** — Queries `Trigger_Handler__c` records with dependency on `ADV_PackageInfo_SVC`.

## Consequences

### Positive

- **Enforced dependency direction**: The package boundary prevents common infrastructure from accidentally depending on domain code.
- **Independent versioning**: `nppatch-common` can be versioned and released independently.
- **Faster feedback**: Changes isolated to one package only require rebuilding that package.
- **Clearer architecture**: Developers can see at a glance what is framework vs. domain.
- **Reuse potential**: `nppatch-common` could theoretically be consumed by other packages.

### Negative

- **Deployment complexity**: CCI flows must deploy `force-app-common` before `force-app`. A custom flow step is required.
- **Refactoring required**: Moving classes across packages requires careful dependency analysis. Some methods had to be relocated (`runFuture`, `toggleTriggerState`).
- **Split test execution**: Test classes remain in `force-app` since they reference domain test helpers, meaning `nppatch-common` has no test coverage within its own package boundary.
- **API breakage for toggleTriggerState**: Any custom code calling `TDTM_ProcessControl.toggleTriggerState()` must update to `TDTM_Config_API.toggleTriggerState()`.

### Mitigations

1. **CCI flow override**: Added a `deploy` step for `force-app-common` before `deploy_unmanaged` in the `dev_org` flow.
2. **Test classes in force-app**: All TDTM test classes remain in `force-app` where they can access domain test utilities. Since both packages share the `nppatch` namespace, tests in `force-app` can still exercise common classes.
3. **Verified deployment**: Both packages deploy cleanly via `cci flow run dev_org`.

## Alternatives Considered

### Keep everything in one package
Rejected because it provides no enforcement of dependency boundaries and results in a monolithic package.

### Three or more packages
Considered splitting further (e.g., separate error handling, separate TDTM), but the additional deployment complexity was not justified given current codebase size.

### Move all TDTM classes including Config_API
The original plan called for moving TDTM_Config_API to common, but dependency analysis revealed it references `TDTM_ObjectDataGateway` and `TDTM_TriggerHandler` in 8+ locations. The refactoring cost to abstract those dependencies was not justified.

## References

- PR #39: Create nppatch-common package with foundational infrastructure
- ADR-0005: Org-Dependent Unlocked Package
- [Salesforce: Unlocked Package Dependencies](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_create_pkg_ver_deps.htm)
