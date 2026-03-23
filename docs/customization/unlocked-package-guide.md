# Working with an Unlocked Package

## What is an Unlocked Package?

NPPatch is distributed as a **namespaced unlocked 2GP package**. The most important thing this means is that the community — not Salesforce — controls what gets built and when it ships. But it also changes how the package works in your org compared to the original NPSP managed packages.

### Managed Package vs. Unlocked Package

| Aspect | Managed Package (original NPSP) | Unlocked Package (NPPatch) |
|--------|---|---|
| **Source Code** | Open source, but obfuscated in subscriber orgs | Open source, and visible in subscriber orgs |
| **Release Process** | Vendor controls what ships and when | Community controls what ships and when |
| **Extending** | Limited to configuration and new objects outside the package | Deploy customizations and extensions on top of the package |
| **Changing Package Code** | Not possible; only vendor can modify | Contributors work from the source repository and ship new versions |
| **Namespace** | Controlled by vendor | Uses namespace injection — viable to fork and publish under a different namespace |
| **Upgrades** | Vendor pushes updates on their timeline | Community publishes versions; orgs upgrade when ready |
| **Dependencies** | Black box; no visibility into dependencies | Full transparency into code dependencies |

### Key Distinction

The freedom NPPatch provides is in the **release process**, not in-org editing. Subscribers can view all source code and deploy extensions on top of the package, but cannot directly edit namespaced package components inside their own org instance. To change package code, contributors work from the [source repository](https://github.com/Sundae-Shop-Consulting/nppatch) — the community decides what gets merged and when new versions ship.

NPPatch uses CumulusCI's namespace injection so that the source code contains very few hard-coded namespace references. This makes it viable for consulting firms or organizations that serve multiple clients to fork the repository and publish under their own namespace.

## What You Can Do

### 1. View and Audit All Source Code

NPSP's source code was always available on GitHub, but managed packages obfuscated it in subscriber orgs. With an unlocked package, the code is visible in the org too — you can inspect trigger handlers, services, and utility classes directly:

```
force-app/
├── nppatch-main/
│   └── default/
│       └── classes/
│           ├── OPP_OpportunityBeforeInsert_TDTM.cls  ✓ Visible
│           ├── CRLP_RollupProcessor.cls               ✓ Visible
│           └── UTIL_Namespace.cls                     ✓ Visible
└── nppatch-common/
    └── tdtm/
        └── classes/
            └── TDTM_TriggerHandler.cls                ✓ Visible
```

This enables you to:

- Understand how business logic works at the code level
- Debug issues by reading the actual implementation
- Trace execution paths through trigger handlers, services, and selectors
- Evaluate changes in new versions before upgrading

### 2. Deploy Extensions on Top of the Package

You can deploy your own customizations alongside the package — custom fields on package objects, new Apex classes, new LWC components, and more. These live outside the package namespace and survive upgrades.

You can add custom fields to any NPPatch object by deploying `.field-meta.xml` files in your unpackaged or custom package directory:

```
your-org-customizations/
├── classes/
│   └── CUSTOM_ContactValidation_TDTM.cls    ✓ Your code — survives upgrades
├── objects/
│   └── Account/fields/
│       └── Program_Area__c.field-meta.xml    ✓ Your field — survives upgrades
└── lwc/
    └── customGiftForm/                       ✓ Your component — survives upgrades
```

### 3. Extend the TDTM Framework

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

## Upgrading

### How Upgrades Work

When the community publishes a new NPPatch version, you upgrade by installing the new package version into your org. The upgrade replaces all namespaced package components with the new version.

### What Survives an Upgrade

Your extensions and customizations that live outside the package namespace are preserved:

✓ Custom fields you added (in unpackaged or your namespace)
✓ Custom Trigger_Handler__c records you created
✓ Custom Apex classes you wrote (outside the package)
✓ Custom objects you created
✓ Configuration data (custom settings, custom metadata you added)
✓ Custom page layouts and record type customizations

All namespaced package components (Apex classes, triggers, LWC, custom objects, custom fields, custom metadata) are replaced with the new version.

### Test Upgrades in a Sandbox First

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

## Recommended Project Structure

Organize your repository to keep your extensions separate from the package:

```
your-nppatch-project/
├── README.md
├── .gitignore
├── .github/
│   └── workflows/              # CI/CD pipelines
│       └── deploy.yml
├── force-app/
│   ├── main/
│   │   └── default/            # Package code (replaced on upgrade)
│   │       ├── classes/        # ~630 nppatch classes
│   │       ├── objects/        # Package objects
│   │       └── lwc/            # ~120 LWC components
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

## Customization Decision Checklist

Before adding functionality to your NPPatch org, ask yourself:

- [ ] Can I achieve this via configuration (Trigger_Handler__c settings, custom metadata)?
- [ ] Would an extension (new handler class, companion package) work?
- [ ] Should this be contributed back to the community repository as a package improvement?
- [ ] Have I documented what I'm adding and why?
- [ ] Will my team understand this customization in 6 months?
- [ ] Can this be tested automatically?

In most cases, the best approach is to **extend on top of the package** rather than trying to change package code. If you've identified a bug or improvement that would benefit everyone, consider [contributing it](https://github.com/Sundae-Shop-Consulting/nppatch) so it ships in the next version.

## Next Steps

- **[Extending NPPatch](extending.md)** - Create new handlers, metadata, and custom code
- **[Architecture Overview](../architecture/overview.md)** - Understand the technical foundation
- **[Getting Started](../getting-started/overview.md)** - Initial setup and configuration

---

*If you see something that could be improved, please create an issue or email admin@nppatch.com.*
