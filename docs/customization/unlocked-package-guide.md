# Working with an Unlocked Package

## What is an Unlocked Package?

NPPatch is distributed as a **namespaced unlocked 2GP package**, which fundamentally changes how you work with the codebase compared to traditional managed packages like the original NPSP.

### Managed Package vs. Unlocked Package

| Aspect | Managed Package | Unlocked Package |
|--------|---|---|
| **Source Code** | Hidden; cannot be viewed or modified | Visible and modifiable |
| **Customization** | Limited to configuration and new objects | Unlimited; can modify any code |
| **Namespacing** | Managed namespace applied | Managed namespace with editable code |
| **Upgrades** | Managed package controls; protected components | Custom changes may be overwritten by upgrades |
| **Version Control** | Not stored in your source tree | Can be stored alongside your modifications |
| **Dependencies** | Black box; no visibility into dependencies | Full transparency into code dependencies |

### Key Implication

Because NPPatch is an **unlocked package**, you have complete access to and control over the underlying Apex code, object definitions, and Lightning Web Components. This flexibility comes with responsibility: when you modify package code, future upgrades may introduce conflicts or overwrite your changes.

## What You Can Now Do

### 1. View and Modify Apex Code

All trigger handlers, services, selectors, and utility classes are visible and editable:

```
force-app/
├── main/
│   └── default/
│       └── classes/
│           ├── OPP_OpportunityBeforeInsert_TDTM.cls  ✓ Can view and edit
│           ├── CRLP_RollupProcessor.cls               ✓ Can view and edit
│           └── UTIL_Namespace.cls                     ✓ Can view and edit
└── tdtm/
    ├── triggerHandlers/
    │   └── opportunity/
    │       └── OPP_OpportunityAfterUpdate_TDTM.cls    ✓ Can view and edit
    └── classes/
        └── TDTM_TriggerHandler.cls                    ✓ Can view and edit
```

This enables you to:

- Understand how business logic works at the code level
- Debug issues by reading the actual implementation
- Make surgical modifications without forking the entire package
- Trace execution paths through trigger handlers, services, and selectors

### 2. Add Fields Directly to Package Objects

Unlike managed packages, you can add custom fields to any NPPatch object:

```
force-app/main/default/objects/Account/fields/
├── nppatch__Custom_Nonprofit_ID__c.field-meta.xml      ✓ New field - your org only
├── nppatch__Program_Area__c.field-meta.xml              ✓ New field - your org only
└── (package objects)                                  ✓ Can also extend
```

You can create custom fields on:
- **npe5\__Account** (Package household/organization accounts)
- **Contact** (Enhanced with address, household, affiliation data)
- **npe3\__Opportunity** (Package opportunities with allocation data)
- Any other package-provided object

Simply add `.field-meta.xml` files in your unpackaged or custom package directory.

### 3. Modify Trigger Handlers

You can edit existing trigger handlers without rebuilding from scratch:

```apex
// ADDR_Contact_TDTM.cls - You can add logic here:

public class ADDR_Contact_TDTM extends TDTM_Runnable {
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // Original package logic...

        // ✓ Add your custom business rules here
        if (shouldApplyCustomLogic()) {
            applyCustomAddressValidation(listNew);
        }

        return dmlWrapper;
    }
}
```

### 4. Customize Lightning Web Components (LWC)

All LWC components are visible and can be modified:

```
force-app/main/default/lwc/
├── geFormWidget/
│   ├── geFormWidget.html              ✓ Can modify markup
│   ├── geFormWidget.js                ✓ Can modify logic
│   └── geFormWidget.css               ✓ Can modify styling
├── geHome/                             ✓ Can modify any component
└── ...
```

You can:
- Customize component templates and layouts
- Add new business logic to component controllers
- Extend existing components with new features
- Modify styling without forking the entire component

### 5. Extend the TDTM Framework

Register new trigger handlers via `Trigger_Handler__c` custom metadata without modifying package code:

```apex
// YOUR custom trigger handler - in unpackaged or separate package

public class CUSTOM_ContactValidation_TDTM extends TDTM_Runnable {
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper wrapper = new DmlWrapper();

        // Your custom validation logic
        for (Contact c : (List<Contact>)listNew) {
            if (c.Email != null && !isValidEmail(c.Email)) {
                wrapper.objectsWithError.add(
                    new ErrorRecord(c, 'Invalid email format')
                );
            }
        }

        return wrapper;
    }

    private Boolean isValidEmail(String email) {
        return email.contains('@') && email.contains('.');
    }
}
```

Then register in the UI:
1. Navigate to **Trigger Handlers** list view
2. Create new `Trigger_Handler__c` record:
   - **Class**: `CUSTOM_ContactValidation_TDTM`
   - **Object**: `Contact`
   - **Trigger Action**: Select trigger events (e.g., BeforeInsert, BeforeUpdate)
   - **Load Order**: Set execution sequence
   - **Active**: Enabled by default

## The Upgrade Tradeoff

### The Risk: Changes Get Overwritten

When NPPatch publishes an upgrade to a newer version, the package installation process may overwrite your direct modifications to package code:

```
Scenario: You've modified OPP_OpportunityBeforeInsert_TDTM.cls

Version 1.0 (Your install)
  └─ OPP_OpportunityBeforeInsert_TDTM.cls
       ├─ Package functionality (lines 1-100)
       └─ YOUR custom logic (lines 101-150)

↓ Package upgrade to 2.0

Version 2.0 (After upgrade)
  └─ OPP_OpportunityBeforeInsert_TDTM.cls
       ├─ Package functionality - UPDATED (lines 1-120)
       └─ YOUR custom logic - LOST! ✗
```

### The Solution: Best Practices

#### 1. Track All Modifications in Version Control

Store your customizations in a source control system (Git, GitHub, Bitbucket, etc.) with clear separation from the package:

```
Repository structure:
├── force-app/
│   ├── main/default/     # Package code (managed)
│   └── unpackaged/       # Your customizations (tracked in Git)
│       ├── classes/
│       │   └── CUSTOM_*.cls              ✓ Your code
│       ├── objects/
│       │   └── Account/fields/
│       │       └── Custom_Field__c.xml   ✓ Your code
│       └── lwc/
│           └── customGiftForm/           ✓ Your component
└── .git/
    └── (full history of all your changes)
```

**Benefits:**
- Audit trail of all modifications
- Easy rollback if upgrade breaks something
- Collaboration with team members
- Deployment consistency across orgs

#### 2. Use a Diff Tool Before Upgrading

Before installing a package upgrade, preview what will change:

```bash
# Example using Git (if you store the package code)
git diff v1.0..v2.0 -- force-app/main/default/classes/OPP_*.cls

# Identify which classes changed
# Example output:
# - OPP_OpportunityBeforeInsert_TDTM.cls        (CHANGED - review carefully)
# - OPP_OpportunityAfterUpdate_TDTM.cls         (CHANGED - review carefully)
# - OPP_OpportunitySvc_SVC.cls                  (CHANGED - review carefully)
```

**Process before upgrading:**
1. Get a list of changes from the release notes
2. For each changed file you've customized, review the diff
3. Identify breaking changes or conflicts
4. Plan for manual re-application in your custom code

#### 3. Prefer Extension Over Modification

When possible, extend package functionality instead of modifying it directly:

**❌ Less Ideal: Modifying package code directly**
```apex
// force-app/main/default/classes/OPP_OpportunityBeforeInsert_TDTM.cls
public class OPP_OpportunityBeforeInsert_TDTM extends TDTM_Runnable {
    public override DmlWrapper run(List<SObject> listNew, ...) {
        // ... package logic ...

        // YOUR modification here - will be lost on upgrade!
        if (shouldApplyCustomRule()) {
            applyCustomRule(listNew);
        }
    }
}
```

**✓ Better: Create a separate handler**
```apex
// unpackaged/classes/CUSTOM_OpportunityValidation_TDTM.cls
public class CUSTOM_OpportunityValidation_TDTM extends TDTM_Runnable {
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper wrapper = new DmlWrapper();

        // Your custom logic runs alongside package logic
        for (Opportunity opp : (List<Opportunity>)listNew) {
            if (shouldApplyCustomRule(opp)) {
                applyCustomRule(opp);
            }
        }

        return wrapper;
    }
}
```

Register this handler in the UI with appropriate `Load_Order__c` to control execution sequence.

**Advantages:**
- Your code survives package upgrades
- Easier to test and maintain
- Clear separation of concerns
- Can be disabled without touching package code

#### 4. Test Upgrades in a Sandbox First

Always validate package upgrades in a development or staging sandbox before deploying to production:

```
Sandbox Testing Checklist:
☐ Refresh sandbox to mirror production
☐ Install the upgrade package
☐ Run your test suite: sfdx force:apex:test:run
☐ Verify critical business processes still work
☐ Confirm your custom handlers still execute (check Trigger_Handler__c)
☐ Check logs for errors or warnings
☐ If issues found, understand the cause before production deployment
```

## How Package Upgrades Work for Unlocked Packages

### Installation Process

When you upgrade NPPatch:

1. **Salesforce validates the package** against your org's configuration
2. **Namespace metadata is updated** - all `nppatch__` prefixed items are replaced with new versions
3. **Your customizations are preserved** if they're in separate locations (unpackaged directory, separate package)
4. **Your direct modifications to package code are overwritten** with the new version's code

### Package Components

```
nppatch Package Contents (namespace: nppatch__):
├── Apex Classes         (100+)
├── Apex Triggers        (20+)
├── Custom Objects       (15+)
├── Custom Metadata Types (12+)
├── Custom Fields        (100+)
├── Flows               (8+)
└── LWC Components      (50+)
```

When upgrading, **all** of these are replaced with the new version's components.

### What Survives an Upgrade

✓ Custom fields you added (in unpackaged or your namespace)
✓ Custom Trigger_Handler__c records you created
✓ Custom Apex classes you wrote (if in unpackaged directory)
✓ Custom objects you created
✓ Configuration data (custom settings, custom metadata you added)
✓ Custom page layouts and record type customizations

✗ Direct modifications to package classes
✗ Direct modifications to package LWC components
✗ Direct modifications to package triggers
✗ Direct modifications to package custom fields (will revert to package-defined state)

## Recommended Project Structure

Organize your repository to keep customizations separate:

```
your-nppatch-project/
├── README.md
├── .gitignore
├── .github/
│   └── workflows/              # CI/CD pipelines
│       └── deploy.yml
├── force-app/
│   ├── main/
│   │   └── default/            # Package code (managed - review but don't modify)
│   │       ├── classes/        # 100+ nppatch classes
│   │       ├── triggers/       # TDTM triggers
│   │       ├── objects/        # Package objects
│   │       └── lwc/            # Package components
│   └── unpackaged/             # YOUR customizations (GIT TRACKED)
│       ├── classes/
│       │   ├── CUSTOM_ContactValidation_TDTM.cls
│       │   ├── CUSTOM_OpportunitySvc_SVC.cls
│       │   └── CUSTOM_MyUtilities.cls
│       ├── objects/
│       │   └── Account/
│       │       └── fields/
│       │           ├── Program_Area__c.field-meta.xml
│       │           └── Nonprofit_ID__c.field-meta.xml
│       ├── lwc/
│       │   └── customGiftForm/
│       │       ├── customGiftForm.html
│       │       ├── customGiftForm.js
│       │       └── customGiftForm.js-meta.xml
│       └── staticresources/    # Custom resources if needed
├── unpackaged/                 # Configuration (Metadata API deployments)
│   ├── flowDefinitions/
│   ├── layouts/
│   └── recordTypes/
├── sfdx-project.json
└── scripts/
    └── install.sh              # Installation scripts
```

## Modification Checklist

Before modifying any NPPatch code, ask yourself:

- [ ] Does this modification need to survive package upgrades?
- [ ] Would an extension (new handler class) be better than a modification?
- [ ] Can I achieve this via configuration (Trigger_Handler__c settings)?
- [ ] Have I documented what I'm changing and why?
- [ ] Will my team understand this change in 6 months?
- [ ] Can this be tested automatically?

If you answer "yes" to the first question, consider an extension instead.

## Next Steps

- **[Extending NPPatch](extending.md)** - Create new handlers, metadata, and custom code
- **[Architecture Overview](../architecture/overview.md)** - Understand the technical foundation
- **[Getting Started](../getting-started/overview.md)** - Initial setup and configuration
