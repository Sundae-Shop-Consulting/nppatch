# Extending NPPatch

NPPatch's extensibility is built on industry-standard patterns that encourage adding functionality without modifying package code. This guide covers the approved patterns for extending the platform.

## The Extension Principle

> "Extend, don't override. Configure, don't code."

The best customizations follow this hierarchy:

1. **Configuration** - Adjust via settings, custom metadata, or Trigger_Handler__c records (no code)
2. **Extension** - Add new handlers, services, or components (your code)
3. **Modification** - Alter existing package code (last resort; see [Unlocked Package Guide](unlocked-package-guide.md))

This guide focuses on levels 1 and 2.

## Pattern 1: Adding Trigger Handlers via TDTM

The TDTM framework allows you to add new trigger handlers without modifying the core package trigger infrastructure.

### How TDTM Works

The `TDTM_TriggerHandler` class reads the `Trigger_Handler__c` custom object to determine which handlers to execute for a given object and trigger event:

```
Data Change → Package Trigger (e.g., trg_Contact)
                     ↓
         TDTM_TriggerHandler.run()
                     ↓
         Query Trigger_Handler__c for Contact + BeforeInsert
                     ↓
         For each matching record:
            - Instantiate the class
            - Call run() method
            - Collect DML operations
                     ↓
         Execute all DML at transaction end
```

### Creating a Custom Trigger Handler

#### Step 1: Write the Handler Class

Create a class that extends `TDTM_Runnable`:

```apex
// unpackaged/classes/CUSTOM_ContactPhoneValidation_TDTM.cls

public class CUSTOM_ContactPhoneValidation_TDTM extends TDTM_Runnable {

    /*******************************************************
     * @description Validates contact phone numbers in US format
     * @param listNew Contacts being inserted/updated
     * @param listOld Previous contact values (for updates)
     * @param triggerAction Which trigger event (BeforeInsert, AfterUpdate, etc.)
     * @param objResult SObjectDescribe of Contact
     * @return DmlWrapper with any validation errors
     *******************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();

        // Only validate on insert and update
        if (triggerAction != TDTM_Runnable.Action.BeforeInsert &&
            triggerAction != TDTM_Runnable.Action.BeforeUpdate) {
            return dmlWrapper;
        }

        List<Contact> contacts = (List<Contact>) listNew;

        for (Contact c : contacts) {
            // Skip if no phone
            if (String.isBlank(c.Phone)) {
                continue;
            }

            // Validate US phone format: (XXX) XXX-XXXX
            if (!isValidPhoneFormat(c.Phone)) {
                dmlWrapper.objectsWithError.add(
                    new ErrorRecord(c, 'Phone must be in format (XXX) XXX-XXXX')
                );
            }
        }

        return dmlWrapper;
    }

    private static Boolean isValidPhoneFormat(String phone) {
        // Simple validation - customize as needed
        String pattern = '^\\([0-9]{3}\\) [0-9]{3}-[0-9]{4}$';
        return Pattern.matches(pattern, phone.trim());
    }
}
```

#### Step 2: Configure in the UI

Register your handler in the `Trigger_Handler__c` object:

1. Navigate to **Setup** → **Custom Objects & Fields** → **Trigger Handlers**
2. Click **New**
3. Fill in the fields:

| Field | Value |
|-------|-------|
| **Trigger Handler Name** | Contact Phone Validation |
| **Object** | Contact |
| **Class** | CUSTOM_ContactPhoneValidation_TDTM |
| **Trigger Action** | BeforeInsert, BeforeUpdate |
| **Load Order** | 10 (or position relative to other handlers) |
| **Active** | ☑ (checked) |
| **Asynchronous** | ☐ (unchecked for validation) |

#### Step 3: Test the Handler

Write a test to verify your handler works:

```apex
@IsTest
private class CUSTOM_ContactPhoneValidation_TEST {

    @IsTest
    static void testValidPhoneFormat() {
        Contact c = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Phone = '(555) 123-4567'
        );

        Test.startTest();
        CUSTOM_ContactPhoneValidation_TDTM handler = new CUSTOM_ContactPhoneValidation_TDTM();
        TDTM_Runnable.DmlWrapper result = handler.run(
            new List<Contact>{ c },
            null,
            TDTM_Runnable.Action.BeforeInsert,
            Schema.Contact.sObjectType.getDescribe()
        );
        Test.stopTest();

        // Valid phone - no errors
        System.assertEquals(0, result.objectsWithError.size());
    }

    @IsTest
    static void testInvalidPhoneFormat() {
        Contact c = new Contact(
            FirstName = 'John',
            LastName = 'Smith',
            Phone = '555-1234'  // Invalid format
        );

        Test.startTest();
        CUSTOM_ContactPhoneValidation_TDTM handler = new CUSTOM_ContactPhoneValidation_TDTM();
        TDTM_Runnable.DmlWrapper result = handler.run(
            new List<Contact>{ c },
            null,
            TDTM_Runnable.Action.BeforeInsert,
            Schema.Contact.sObjectType.getDescribe()
        );
        Test.stopTest();

        // Invalid phone - should have error
        System.assertEquals(1, result.objectsWithError.size());
        System.assertEquals('Phone must be in format (XXX) XXX-XXXX',
            result.objectsWithError[0].getFirstError());
    }
}
```

### Handler Execution Order

When multiple handlers exist for the same object and trigger event, they execute in order of their `Load_Order__c` field:

```
Contact BeforeInsert handlers:
├─ Load Order 1  → Package handler: ADDR_Contact_TDTM
├─ Load Order 5  → Package handler: ACCT_IndividualAccounts_TDTM
├─ Load Order 10 → YOUR handler: CUSTOM_ContactPhoneValidation_TDTM
└─ Load Order 20 → YOUR handler: CUSTOM_ContactEnrichment_TDTM
```

**Guidelines:**
- Use 1-5 for early handlers (validation, preprocessing)
- Use 10-20 for main business logic
- Use 25+ for post-processing, notifications
- Leave gaps (5, 10, 20) so others can insert handlers between yours

### Asynchronous Handlers

For expensive operations that shouldn't block the user, mark the handler as asynchronous:

```apex
public class CUSTOM_ContactDataEnrichment_TDTM extends TDTM_Runnable {

    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // This handler is marked Asynchronous__c = true
        // It runs in a separate transaction, so expensive operations are OK

        DmlWrapper dmlWrapper = new DmlWrapper();
        List<Contact> contacts = (List<Contact>) listNew;

        // Call expensive external API or do complex processing
        Map<String, ContactEnrichment> enrichments = callEnrichmentAPI(contacts);

        // Update contact fields with enriched data
        for (Contact c : contacts) {
            ContactEnrichment data = enrichments.get(c.Email);
            if (data != null) {
                c.BillingCity = data.city;
                c.BillingState = data.state;
                dmlWrapper.objectsToUpdate.add(c);
            }
        }

        return dmlWrapper;
    }
}
```

Configuration:
- Set **Asynchronous__c** = true
- Only works for AfterInsert, AfterUpdate, AfterDelete, AfterUndelete
- Handler runs in a future context, in a separate transaction

## Pattern 2: Creating Custom Rollup Definitions

The Customizable Rollup (CRLP) framework uses custom metadata to define rollup calculations without code.

### Rollup__mdt Structure

The `Rollup__mdt` custom metadata type stores definitions for sum, count, average, and other aggregate operations:

| Field | Purpose | Example |
|-------|---------|---------|
| **Summary_Object__c** | Where the rollup result is stored | Account |
| **Summary_Field__c** | Which field gets the result | Total_Donations__c |
| **Detail_Object__c** | Where the data comes from | Opportunity |
| **Detail_Field__c** | Which field to aggregate | Amount |
| **Amount_Field__c** | For filtered aggregations | (optional) Soft_Credit_Amount__c |
| **Operation__c** | Type of calculation | Sum, Count, Average, Largest, Smallest, Years_Donated, etc. |
| **Filter_Group__c** | Which filter rules to apply | (if using Filter_Rule__mdt) |
| **Date_Object__c** | For date-based operations | Opportunity |
| **Date_Field__c** | Which date field to check | CloseDate |
| **Active__c** | Enable/disable this rollup | true |
| **Use_Fiscal_Year__c** | Use org's fiscal year | false |

### Creating a Custom Rollup

You can use the Salesforce UI or Metadata API. UI approach:

1. Navigate to **Setup** → **Custom Metadata Types** → **Rollup**
2. Click **New**
3. Fill in the metadata record:

**Example: Total Gifts in Past Year by Contact**

| Field | Value |
|-------|-------|
| Label | Contact Gifts Past Year |
| Summary Object | Contact |
| Summary Field | Gifts_Past_Year__c |
| Detail Object | Opportunity |
| Detail Field | Amount |
| Operation | Sum |
| Date Object | Opportunity |
| Date Field | CloseDate |
| Date Bound Operation Type | Current_Calendar_Year |
| Active | ☑ |

The CRLP engine automatically:
- Queries Opportunities related to the Contact
- Sums the Amount field
- Filters to current calendar year
- Updates `Contact.Gifts_Past_Year__c`

### Supported Operations

```
Count            - Number of records matching criteria
Sum              - Total of numeric field
Average          - Mean value of numeric field
Largest          - Maximum value
Smallest         - Minimum value
First            - First value (by created date)
Last             - Most recent value
Years_Donated    - Count of distinct years with donations
Donor_Streak     - Consecutive years of donations
Best_Year        - Calendar year with highest total (value is year)
Best_Year_Total  - Highest annual total amount
```

## Pattern 3: Adding Custom Field Mappings for Data Import

The Data Import framework uses `Data_Import_Field_Mapping__mdt` to configure how fields map from the import object to target objects.

### Field Mapping Metadata

You can define mappings that the Data Import process uses automatically:

| Field | Purpose | Example |
|-------|---------|---------|
| **Target_Object_Mapping__c** | Which object import mapping this belongs to | Contact |
| **Source_Field_API_Name__c** | Field on Data_Import__c object | Contact_1_Email__c |
| **Target_Field_API_Name__c** | Field on target object | Contact.Email |
| **Required__c** | Whether field is required for import | true / false |
| **Is_Deleted__c** | Mark mapping as inactive | false |

### Adding Custom Field Mappings

1. Navigate to **Setup** → **Custom Metadata Types** → **Data Import Field Mapping**
2. Click **New**
3. Example mapping: Import contact department to custom field

| Field | Value |
|-------|-------|
| Label | Contact Department Import |
| Target Object Mapping | Contact |
| Source Field API Name | Contact_1_Department__c |
| Target Field API Name | Department__c |
| Required | ☐ |

The Data Import process then:
- Reads `DataImport__c.Contact_1_Department__c`
- Maps to `Contact.Department__c`
- Applies the same transformation rules as native mappings

## Pattern 4: Using Custom Metadata for Configuration

Instead of hardcoding configuration, leverage custom metadata types for configuration-as-code:

### Create a Custom Metadata Type

```
Setup → Custom Metadata Types → New
```

**Example: Nonprofit Configuration**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Nonprofit Configuration</label>
    <pluralLabel>Nonprofit Configurations</pluralLabel>
    <visibility>Public</visibility>
</CustomMetadata>
```

### Query in Apex

```apex
public class CUSTOM_ConfigManager {

    public static final String DEFAULT_REGION = 'US';

    public static String getConfigValue(String configName, String settingName) {
        // Query custom metadata (cache-friendly)
        List<Nonprofit_Config__mdt> configs = [
            SELECT Value__c
            FROM Nonprofit_Config__mdt
            WHERE DeveloperName = :configName
        ];

        if (configs.isEmpty()) {
            return null;
        }

        // Parse JSON or delimited values as needed
        return configs[0].Value__c;
    }

    public static Boolean isFeatureEnabled(String featureName) {
        List<Feature_Toggle__mdt> toggles = [
            SELECT Enabled__c
            FROM Feature_Toggle__mdt
            WHERE DeveloperName = :featureName
        ];

        return !toggles.isEmpty() && toggles[0].Enabled__c;
    }
}
```

**Benefits:**
- Configuration stored in version control
- No Salesforce UI required (can be deployed as code)
- Cached globally (better performance than custom settings)
- Different values per org (deploy different versions)

## Pattern 5: Creating Custom LWC Components

NPPatch includes many LWC components that interact with the data model. You can create custom components:

### Create Component Files

```
unpackaged/lwc/customDonationForm/
├── customDonationForm.html
├── customDonationForm.js
├── customDonationForm.js-meta.xml
└── customDonationForm.css
```

### Extend Existing Components

```html
<!-- unpackaged/lwc/customDonationForm/customDonationForm.html -->
<template>
    <lightning-card title="Custom Donation Form">
        <div class="slds-box slds-theme_default">
            <!-- Wrap and extend existing component -->
            <c-ge-form-widget
                form-data={formData}
                onhandlesave={handleSave}
                onhandlecancel={handleCancel}
            ></c-ge-form-widget>

            <!-- Add custom fields -->
            <lightning-input
                label="Campaign Source"
                value={campaignSource}
                onchange={handleCampaignChange}
            ></lightning-input>
        </div>
    </lightning-card>
</template>
```

```javascript
// customDonationForm.js
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomDonationForm extends LightningElement {
    @api formData;
    campaignSource = '';

    handleSave(event) {
        // Add custom validation
        if (!this.campaignSource) {
            this.showError('Campaign source is required');
            return;
        }

        // Extend the form data
        const enrichedData = {
            ...event.detail,
            Campaign_Source__c: this.campaignSource
        };

        // Dispatch custom event
        this.dispatchEvent(
            new CustomEvent('custommemodonatonsave', {
                detail: enrichedData
            })
        );
    }

    handleCampaignChange(event) {
        this.campaignSource = event.target.value;
    }

    handleCancel() {
        // Handle cancel
    }

    showError(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }
}
```

### Register in Page Layout or App

Add your custom component to:
- Lightning Record Pages (via Page Layouts)
- Lightning App Builder
- Custom Visualforce pages that embed LWC

## Pattern 6: Adding Custom Fields to NPPatch Objects

Since NPPatch is an unlocked package, you can add custom fields directly:

### Create Custom Field Metadata

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Account.Program_Area__c</fullName>
    <description>Primary program area for this organization</description>
    <externalId>false</externalId>
    <inlineHelpText>Select the primary focus area</inlineHelpText>
    <label>Program Area</label>
    <required>false</required>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value>
                <fullName>Education</fullName>
                <default>false</default>
                <label>Education</label>
            </value>
            <value>
                <fullName>Healthcare</fullName>
                <default>false</default>
                <label>Healthcare</label>
            </value>
            <value>
                <fullName>Social Services</fullName>
                <default>false</default>
                <label>Social Services</label>
            </value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
```

### Deploy Custom Fields

Use Salesforce CLI:

```bash
# Deploy custom fields to your org
sfdx force:source:deploy -p force-app/unpackaged --targetusername myorg

# Or deploy just the field
sfdx force:source:deploy -m CustomField:Account.Program_Area__c --targetusername myorg
```

## Pattern 7: Extending fflib Application Layer

NPPatch uses the Apex Enterprise Patterns (fflib) framework. You can extend it with custom services and selectors:

### Create Custom Service

```apex
// unpackaged/classes/CUSTOM_DonationEnrichment_SVC.cls

public class CUSTOM_DonationEnrichment_SVC {

    public static void enrichDonations(List<Opportunity> donations) {
        // Call external API to enrich donation data

        // Get Salesforce data
        List<Account> accounts = new AccountSelector().selectById(
            new Map<Id, Opportunity>(donations).values().keySet()
        );

        for (Opportunity donation : donations) {
            Account account = accounts.get(donation.AccountId);
            // Apply enrichment logic
            enrichData(donation, account);
        }
    }

    private static void enrichData(Opportunity donation, Account account) {
        // Custom business logic
    }
}
```

### Create Custom Selector

```apex
// unpackaged/classes/CUSTOM_DonationSelector_SEL.cls

public class CUSTOM_DonationSelector_SEL {

    public List<Opportunity> selectByAmountRange(Decimal minAmount, Decimal maxAmount) {
        return [
            SELECT Id, Name, Amount, StageName, CloseDate, AccountId
            FROM Opportunity
            WHERE Amount >= :minAmount
              AND Amount <= :maxAmount
              AND StageName = 'Closed Won'
            ORDER BY CloseDate DESC
        ];
    }

    public List<Opportunity> selectRecentDonations(Integer days) {
        return [
            SELECT Id, Name, Amount, StageName, CloseDate, AccountId
            FROM Opportunity
            WHERE CloseDate >= :System.today().addDays(-days)
              AND StageName = 'Closed Won'
            ORDER BY CloseDate DESC
        ];
    }
}
```

## Pattern 8: Using Separate Companion Package

For complex customizations that need to survive upgrades and be shared across orgs, create a companion package:

### Structure

```
nppatch-customizations/
├── sfdx-project.json          # Separate package definition
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/       # Your custom handlers
│           ├── objects/       # Your custom objects
│           └── lwc/           # Your custom components
└── CHANGELOG.md
```

### Benefits

- Custom code is isolated from NPPatch upgrades
- Can be versioned independently
- Can be installed alongside NPPatch in multiple orgs
- Cleaner separation of concerns
- Easier to share and maintain

### Example sfdx-project.json

```json
{
    "name": "nppatch Customizations",
    "namespace": "hwork_custom",
    "sfdxProjectVersion": "63.0",
    "packageDirectories": [
        {
            "path": "force-app",
            "default": true,
            "package": "nppatch Customizations",
            "versionName": "Version 1.0",
            "versionNumber": "1.0.0.0"
        }
    ],
    "packageAliases": {
        "nppatch Customizations": "0Ho6g000000001CAA"
    }
}
```

## Best Practices Summary

| Pattern | When to Use | Pros | Cons |
|---------|-----------|------|------|
| **Trigger_Handler__c** | Add new logic without modifying package | Survives upgrades, visible in UI | Limited to TDTM framework |
| **Rollup__mdt** | Configure aggregations without code | No code needed, versioned, flexible | Limited to predefined operations |
| **Data_Import_Field_Mapping__mdt** | Add import field mappings | Integrated with import framework | Specific to data import |
| **Custom Metadata Types** | Store configuration | Versioned, cached, queryable | Requires custom query code |
| **Custom LWC** | Build new UI components | Full flexibility, modern UI | Must integrate manually |
| **Custom Fields** | Extend objects with data | Simple, integrated | Adds to schema complexity |
| **Custom Services/Selectors** | Encapsulate business logic | Reusable, testable, clean | Requires fflib knowledge |
| **Companion Package** | Complex customizations | Survives upgrades, isolated | Added complexity |

## Next Steps

- Review [Unlocked Package Guide](unlocked-package-guide.md) for upgrade safety
- Explore [Architecture Overview](../architecture/overview.md) for deep dive into fflib patterns
- Start with Trigger_Handler__c for first customizations (lowest risk)
- Progress to Custom Services as complexity increases
