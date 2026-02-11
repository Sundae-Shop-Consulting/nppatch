# Trigger Framework (TDTM)

## Overview

NPPatch uses **Table-Driven Trigger Management (TDTM)** for all trigger automation. Rather than embedding logic in Salesforce triggers, TDTM externalizes handler configuration to a custom object (`Trigger_Handler__c`), enabling trigger handlers to be managed purely through configuration.

## How TDTM Works

### Architecture

```
┌─────────────────────────────────────────────────────┐
│  Salesforce Trigger (TDTM_Account, TDTM_Contact)    │
│  Minimal boilerplate - just delegates                │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  TDTM_TriggerHandler.run()                          │
│  Central dispatcher - determines action & handlers  │
└────────────────────┬────────────────────────────────┘
                     │
                     ├──▶ Query Trigger_Handler__c for object
                     │
                     ├──▶ Determine trigger action
                     │    (BeforeInsert, AfterUpdate, etc.)
                     │
                     ├──▶ Instantiate handler classes dynamically
                     │
                     └──▶ Execute handlers in configured order
                           (synchronously or asynchronously)
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Individual Handler Classes (_TDTM suffix)          │
│  Implements TDTM_Runnable or TDTM_RunnableMutable   │
│  Returns DmlWrapper with pending operations         │
└────────────────────┬────────────────────────────────┘
                     │
                     ├──▶ Queued DML batched together
                     │
                     ├──▶ Order maintained by foreign keys
                     │
                     └──▶ All operations executed atomically
                           (or rolled back on error)
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Database Operations                                │
│  Single batch INSERT, UPDATE, DELETE per object type │
└─────────────────────────────────────────────────────┘
```

### Execution Flow

1. **Trigger Fires** - A single trigger fires per object (e.g., `TDTM_Opportunity`)
2. **Handler Discovery** - `TDTM_TriggerHandler.run()` queries `Trigger_Handler__c` for the object and trigger action
3. **Handler Instantiation** - Handler classes are dynamically instantiated using `Type.forName()`
4. **Sequential Execution** - Handlers execute in `Run_Order__c` sequence:
   - Each handler implements `TDTM_Runnable.run()` or `TDTM_RunnableMutable.run()`
   - Handler receives trigger records, old records, and trigger action
   - Handler returns a `DmlWrapper` containing any DML to perform
5. **DML Collection** - DML from all handlers is accumulated in a shared `DmlWrapper`
6. **Atomic Persistence** - After all handlers complete, all DML is executed in one batch
7. **Error Handling** - If any DML fails and configured for all-or-nothing, transaction rolls back

### Key Benefits

**Configuration-Driven Automation:**
- Add handlers without modifying code
- Reorder execution by changing `Run_Order__c`
- Enable/disable handlers via `Active__c` checkbox

**Testability:**
- Handlers are pure classes with no trigger-specific code
- Call `handler.run()` directly in unit tests
- No need to insert data and fire triggers to test logic

**Performance:**
- Minimal DML overhead: one INSERT, UPDATE, DELETE per object
- Foreign key ordering prevents constraint violations
- Governor limit efficiency via batching

**Async Support:**
- Handlers can mark `Asynchronous__c = true` to run in future/batch context
- Prevents transaction timeouts on large operations
- Transparent to handler implementation

## Handler Interfaces

### TDTM_Runnable

Standard handler interface that returns a `DmlWrapper`:

```apex
public interface TDTM_Runnable {
    enum Action { BeforeInsert, BeforeUpdate, BeforeDelete,
                  AfterInsert, AfterUpdate, AfterDelete, AfterUnDelete }

    TDTM_Runnable.DmlWrapper run(List<SObject> newList, List<SObject> oldList,
                                  TDTM_Runnable.Action action,
                                  Schema.DescribeSObjectResult describeObj);
}
```

**Usage Pattern:**
```apex
public class OPP_OpportunityAfterInsert_TDTM implements TDTM_Runnable {
    public TDTM_Runnable.DmlWrapper run(List<SObject> newList, List<SObject> oldList,
                                        TDTM_Runnable.Action action,
                                        Schema.DescribeSObjectResult describeObj) {
        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();

        if (action == TDTM_Runnable.Action.AfterInsert) {
            // Query related data
            List<Opportunity> opportunities = (List<Opportunity>) newList;

            // Perform business logic
            List<Allocation__c> allocations = createAllocations(opportunities);

            // Queue DML
            dmlWrapper.objectsToInsert.addAll(allocations);
        }

        return dmlWrapper;
    }
}
```

### TDTM_RunnableMutable

Advanced interface for handlers that directly modify the shared `DmlWrapper`:

```apex
public interface TDTM_RunnableMutable {
    void run(List<SObject> newList, List<SObject> oldList,
             TDTM_Runnable.Action action,
             Schema.DescribeSObjectResult describeObj,
             TDTM_Runnable.DmlWrapper dmlWrapper);
}
```

**Usage Pattern:**
```apex
public class RD2_RecurringDonationAfterInsert_TDTM implements TDTM_RunnableMutable {
    public void run(List<SObject> newList, List<SObject> oldList,
                    TDTM_Runnable.Action action,
                    Schema.DescribeSObjectResult describeObj,
                    TDTM_Runnable.DmlWrapper dmlWrapper) {

        if (action == TDTM_Runnable.Action.AfterInsert) {
            List<Recurring_Donation__c> recurringDonations = (List<Recurring_Donation__c>) newList;

            // Directly manipulate shared DML wrapper
            List<RecurringDonationSchedule__c> schedules = generateSchedules(recurringDonations);
            dmlWrapper.objectsToInsert.addAll(schedules);

            List<Opportunity> installments = generateInstallments(recurringDonations);
            dmlWrapper.objectsToInsert.addAll(installments);
        }
    }
}
```

## DmlWrapper

The `TDTM_Runnable.DmlWrapper` class accumulates DML operations:

```apex
public class TDTM_Runnable {
    public class DmlWrapper {
        public List<SObject> objectsToInsert = new List<SObject>();
        public List<SObject> objectsToUpdate = new List<SObject>();
        public List<SObject> objectsToDelete = new List<SObject>();
        public List<SObject> objectsToUndelete = new List<SObject>();
        public List<ErrorRecord> objectsWithError = new List<ErrorRecord>();

        public void groupByType();  // Sorts objects by type for proper ordering
    }
}
```

**Usage:**
- Handlers populate these lists instead of calling DML directly
- TDTM framework processes all lists after handlers complete
- Foreign key ordering is maintained automatically

## Trigger Handler Configuration

### Trigger_Handler__c Record

Each handler is configured via a record in the `Trigger_Handler__c` custom object:

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `Name` | Text | Display name | "Opportunity Before Insert Processing" |
| `Class__c` | Text (required) | Handler class name | "OPP_OpportunityBeforeInsert_TDTM" |
| `Object__c` | Text (required) | Target object | "Opportunity" |
| `Trigger_Action__c` | Multi-select | When to execute | "Before Insert;After Update" |
| `Active__c` | Checkbox | Enable handler | checked |
| `Asynchronous__c` | Checkbox | Run in future | unchecked (synchronous) |
| `Run_Order__c` | Number | Execution sequence | 10, 20, 30, etc. |
| `Description__c` | Long Text | Handler purpose | "Creates related allocations" |

### Handler Execution Order

Handlers execute in `Run_Order__c` ascending order:

```
Run_Order   Class Name                                  Action
=========   ===================================          ==================
10          OPP_OpportunityBeforeInsert_TDTM           Before Insert
20          OPP_OpportunityValidation_TDTM             Before Insert
30          OPP_OpportunitySoftCredit_TDTM             Before Insert
100         OPP_OpportunityAfterInsert_TDTM            After Insert
110         OPP_AllocationCreation_TDTM                After Insert
120         OPP_RollupUpdate_TDTM                       After Insert
```

Order is critical for:
- Ensuring business rules are checked before allowing inserts
- Populating required fields before child record creation
- Executing rollups after all parent data is finalized

### Async Execution

When `Asynchronous__c = true`:

1. Handler must be executed AFTER data is committed (AfterInsert, AfterUpdate, AfterDelete)
2. Record IDs are passed to handler instead of full records
3. Handler queues a future method or batch job
4. Main transaction completes without waiting

**Best For:**
- Complex queries that hit governor limits
- Bulk operations that take 10+ seconds
- Operations that should not delay users

**Example Configuration:**
```
Name: RD2 Installment Generation
Class: RD2_InstallmentGeneration_TDTM
Object: Recurring_Donation__c
Trigger_Action: After Insert
Asynchronous: ✓ (checked)
Run_Order: 100
```

## All 26 Triggers

NPPatch includes one trigger per object (26 total):

| Trigger | Object | Handles |
|---------|--------|---------|
| TDTM_Account | Account | Org hierarchy, related contact updates |
| TDTM_AccountSoftCredit | Account_Soft_Credit__c | Org soft credit validation |
| TDTM_Address | Address__c | Address verification, formula fields |
| TDTM_Affiliation | Affiliation__c | Primary affiliation tracking |
| TDTM_Allocation | Allocation__c | GAU allocation validation |
| TDTM_Campaign | Campaign | Campaign status tracking |
| TDTM_CampaignMember | CampaignMember | Campaign rollup updates |
| TDTM_Contact | Contact | Household management, address sync |
| TDTM_DataImport | DataImport__c | Batch import processing, validation |
| TDTM_DataImportBatch | DataImportBatch__c | Batch status updates |
| TDTM_EngagementPlan | Engagement_Plan__c | Engagement plan scheduling |
| TDTM_EngagementPlanTask | Engagement_Plan_Task__c | Task creation and assignment |
| TDTM_FormTemplate | Form_Template__c | Form configuration validation |
| TDTM_GeneralAccountingUnit | General_Accounting_Unit__c | GAU rollup calculations |
| TDTM_GrantDeadline | Grant_Deadline__c | Grant deadline tracking |
| TDTM_HouseholdObject | Household__c | Household naming, member rollups |
| TDTM_Lead | Lead | Lead conversion preparation |
| TDTM_Level | Level__c | Level definition validation |
| TDTM_Opportunity | Opportunity | Amount validation, stage rules |
| TDTM_OpportunityContactRole | OpportunityContactRole | Soft credit creation, updates |
| TDTM_PartialSoftCredit | Partial_Soft_Credit__c | Soft credit allocation tracking |
| TDTM_Payment | OppPayment__c | Payment validation, opportunity staging |
| TDTM_RecurringDonation | Recurring_Donation__c | Installment creation, status updates |
| TDTM_Relationship | Relationship__c | Reciprocal relationship creation |
| TDTM_Task | Task | Task type classification |
| TDTM_User | User | User name synchronization |

Each trigger is a thin wrapper:

```apex
// Example: TDTM_Opportunity
trigger TDTM_Opportunity on Opportunity (before insert, before update, before delete,
                                         after insert, after update, after delete,
                                         after undelete) {
    TDTM_TriggerHandler.run(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert,
                            Trigger.isUpdate, Trigger.isDelete, Trigger.isUnDelete,
                            Trigger.new, Trigger.old, Opportunity.sObjectType,
                            new TDTM_ObjectDataGateway());
}
```

## Enabling/Disabling Handlers

### Via Checkbox

Simple enable/disable:

1. Navigate to Setup > Custom > Custom Objects > Trigger Handler
2. Open a handler record
3. Check/uncheck "Active__c"
4. Save

### Programmatically

Disable all triggers during bulk operations:

```apex
// Disable TDTM during data load
TDTM_TriggerHandler.disableTDTM = true;

// ... perform bulk insert ...
List<Opportunity> opportunities = ...;
insert opportunities;

// Re-enable TDTM
TDTM_TriggerHandler.disableTDTM = false;
```

### In Tests

```apex
@isTest
private class OPP_OpportunityAfterInsert_TEST {
    @isTest static void testWithoutTriggers() {
        // Disable TDTM for this test
        TDTM_TriggerHandler.disableTDTM = true;

        // Create opportunity without triggers firing
        Opportunity opp = new Opportunity(
            Name = 'Test',
            Amount = 1000,
            StageName = 'Pledge',
            CloseDate = Date.today()
        );
        insert opp;

        // Re-enable and test handler directly
        TDTM_TriggerHandler.disableTDTM = false;

        OPP_OpportunityAfterInsert_TDTM handler = new OPP_OpportunityAfterInsert_TDTM();
        TDTM_Runnable.DmlWrapper result = handler.run(
            new List<Opportunity>{ opp },
            null,
            TDTM_Runnable.Action.AfterInsert,
            Opportunity.sObjectType
        );

        // Assert the result
        System.assertEquals(0, result.objectsToInsert.size());
    }
}
```

## Adding New Handlers

To add trigger logic without modifying existing code:

### Step 1: Create Handler Class

```apex
public class OPP_NewCustomLogic_TDTM implements TDTM_Runnable {
    public TDTM_Runnable.DmlWrapper run(List<SObject> newList, List<SObject> oldList,
                                        TDTM_Runnable.Action action,
                                        Schema.DescribeSObjectResult describeObj) {
        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();

        if (action == TDTM_Runnable.Action.AfterInsert) {
            List<Opportunity> opportunities = (List<Opportunity>) newList;

            // Custom business logic here

            dmlWrapper.objectsToInsert.addAll(itemsToInsert);
        }

        return dmlWrapper;
    }
}
```

### Step 2: Register Handler

Create a `Trigger_Handler__c` record:

| Field | Value |
|-------|-------|
| Name | My New Opportunity Logic |
| Class__c | OPP_NewCustomLogic_TDTM |
| Object__c | Opportunity |
| Trigger_Action__c | After Insert |
| Active__c | ✓ (checked) |
| Run_Order__c | 200 (after existing handlers) |

### Step 3: Test Handler

```apex
@isTest
private class OPP_NewCustomLogic_TEST {
    @isTest static void testLogic() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            Amount = 500,
            StageName = 'Prospect',
            CloseDate = Date.today()
        );

        OPP_NewCustomLogic_TDTM handler = new OPP_NewCustomLogic_TDTM();
        TDTM_Runnable.DmlWrapper result = handler.run(
            new List<Opportunity>{ opp },
            null,
            TDTM_Runnable.Action.AfterInsert,
            Opportunity.sObjectType
        );

        System.assertEquals(1, result.objectsToInsert.size());
    }
}
```

### Step 4: Deploy

- Deploy class, test, and `Trigger_Handler__c` record
- Handler immediately active when org deployment completes
- No trigger code changes needed

## Default Configuration

On first trigger execution, TDTM automatically loads default handler configuration from `TDTM_DefaultConfig.getDefaultRecords()`. This includes:

- Standard handlers for all objects
- Pre-configured run order
- Safe defaults (some handlers may be inactive)

Customers can override defaults:
- Disable handlers via `Active__c = false`
- Reorder by changing `Run_Order__c`
- Add new handlers

## Error Handling

### Exception Handling

When a handler throws an exception:

1. If exception is "handled" per `ERR_ExceptionHandler.isHandledException()`:
   - Error is logged to `Error__c`
   - Beautiful error message added to record
   - Transaction rolled back gracefully

2. If exception is not handled:
   - Full exception propagates
   - Transaction aborts
   - Error visible to user

### DML Wrapper Error Handling

When `processDMLWithErrors()` is called:

```apex
TDTM_TriggerHandler.processDMLWithErrors(dmlWrapper);
```

- Errors from failed DML are captured in `dmlWrapper.objectsWithError`
- Errors are added to related records via `addError()`
- Partial success is possible with `allOrNothing = false`

## Performance Optimization

### Governor Limits

TDTM minimizes governor limit consumption:

- **Batch DML**: One INSERT, UPDATE, DELETE per object type
- **Query Optimization**: Handlers query only needed fields
- **Async Processing**: Complex handlers run in separate transactions

### Caching

TDTM caches handler configurations:

```apex
private static Map<String, Type> typeMap = new Map<String, Type>();

private static Type getTypeForClassNamed(String str) {
    str = str.toLowerCase();
    if (typeMap.get(str) == null) {
        Type typeInst = Type.forName(str);
        typeMap.put(str, typeInst);
    }
    return typeMap.get(str);
}
```

This prevents repeated type reflection on high-volume operations.

### Workflow Compatibility

TDTM handles workflow rules that run after triggers:

- Caches new record state after handler execution
- Provides correct "old" list if workflow triggers another DML
- Works around Salesforce's "workflow runs after trigger" behavior

## Debugging

### Enable Debug Logging

Set `UTIL_Debug.debugWithInfo()` to log handler execution:

```apex
UTIL_Debug.debug(LoggingLevel.WARN, '****Calling synchronously: ' +
    classToRunName + ' for ' + describeObj.getName());
```

### Check Handler Configuration

Query configuration directly:

```apex
List<Trigger_Handler__c> handlers = [
    SELECT Name, Class__c, Active__c, Run_Order__c
    FROM Trigger_Handler__c
    WHERE Object__c = 'Opportunity'
    ORDER BY Run_Order__c ASC
];
```

### Test Handler Directly

Always test handlers in isolation:

```apex
OPP_OpportunityAfterInsert_TDTM handler = new OPP_OpportunityAfterInsert_TDTM();
TDTM_Runnable.DmlWrapper result = handler.run(testRecords, oldRecords, action, describeObj);
System.debug('DML Wrapper: ' + JSON.serializePretty(result));
```
