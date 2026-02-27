# Gift Entry & Data Import

Gift Entry provides a flexible, template-driven interface for capturing and processing donations. It supports both single-gift entry through a guided form and bulk batch processing of multiple gifts, with configurable field mapping, matching logic, and data validation. Gift Entry is always enabled in NPPatch and requires no configuration to activate.

## Overview

The Gift Entry system has two complementary modes:

- **Single Gift Entry** — a form-based experience for entering one gift at a time with real-time validation and immediate record creation
- **Batch Gift Entry** — bulk processing of multiple gifts grouped in a `DataImportBatch__c` record, with a spreadsheet-style review step before final processing

Both modes share the same underlying data import engine (`BDI_DataImportService`) and field mapping configuration.

## Gift Entry UI

### Gift Entry Form

The `geGiftEntryFormApp` LWC orchestrates the single-gift entry experience. It delegates rendering to `geFormRenderer`, which builds the form dynamically from the active `Form_Template__c` configuration. Key sub-components include:

- **`geFormField`** — renders individual form fields
- **`geFormSection`** — groups fields into labeled sections
- **`geFormWidget`** — handles special field types (allocations, soft credits, payment tokenization)
- **`geDonationMatching`** — finds existing opportunities or payments to match against an incoming gift
- **`geGatewaySelectWidget`** — optional payment gateway selector when `Enable_Gateway_Assignment__c` is enabled in Gift Entry Settings

### Batch Gift Entry

The `geGiftBatch` LWC manages the batch entry workflow:

1. A batch (`DataImportBatch__c`) is created or selected
2. Gifts are entered through the same form interface and saved as `DataImport__c` staging records
3. Users review the gift list via `geBatchGiftEntryTable`
4. A dry run (`GE_GiftEntryController.runBatchDryRun`) can be executed to preview which records will succeed or fail before committing
5. The batch is processed, converting staging records to Opportunities, Payments, and related records

### Batch Creation Wizard

`geBatchWizard` guides users through creating a new gift batch, including setting the batch name, expected total, and selecting which form template to use.

## Form Templates

### Form_Template__c

Form templates define the layout, fields, and validation behavior of the gift entry form. Each template is stored as a JSON configuration blob in `Template_JSON__c` alongside human-readable metadata:

| Field | Purpose |
|-------|---------|
| `Name` | Template display name |
| `Description__c` | Usage notes |
| `Template_JSON__c` | Full template configuration (sections, fields, widgets, validation) |
| `Batch_Gift_Entry_Version__c` | Template version, used by the entry form to detect schema changes |

Templates are created and edited through the **Template Builder**, accessed via the Gift Entry tab. The template builder is implemented by a set of `geTemplateBuilder*` components backed by `geTemplateBuilderService`.

`GE_Template` is the server-side class that loads, validates, and parses template configurations. `BGE_FormTemplate_TDTM` is a trigger handler that prevents deletion of Form_Template__c records while they are associated with active gift batches.

## Data Import Engine

### DataImport__c

The `DataImport__c` object is the staging table for gift entry. Each record represents a single gift to be imported and holds:

- Donor identification fields (contact name, email, account name)
- Donation fields (amount, date, stage, campaign, record type)
- Payment fields (payment method, amount)
- Lookup fields populated after matching (matched Contact, matched Opportunity, etc.)
- Status and error fields showing the result of import processing

### DataImportBatch__c

Batches group multiple `DataImport__c` records for cohesive processing:

| Field | Purpose |
|-------|---------|
| `Name` | Descriptive batch name |
| `Batch_Status__c` | Open, Processing, Completed, Failed |
| `Batch_Description__c` | User notes |
| `Active_Fields__c` | JSON of enabled field mappings for this batch's template |
| `Batch_Process_Size__c` | Number of staging records processed per batch job chunk |

### BDI_DataImportService

`BDI_DataImportService` is the core engine that processes `DataImport__c` records into Salesforce records. Its steps are:

1. **Contact/Account matching** — find or create the donor based on the configured matching rule
2. **Donation matching** — find an existing Opportunity to update, or prepare to create a new one
3. **Field mapping** — translate `DataImport__c` fields to their target object fields using Advanced Mapping
4. **DML** — insert or update Opportunities, Payments, Allocations, and other related records
5. **Status update** — write the import result (Imported, Failed, Dry Run) and any error messages back to the `DataImport__c` record

### Advanced Mapping (BDI_MappingServiceAdvanced)

NPPatch uses Advanced Mapping exclusively. Field mappings are stored in `Data_Import_Field_Mapping__mdt` and `Data_Import_Object_Mapping__mdt` Custom Metadata records, configured through **NPPatch Settings > System Tools > Advanced Mapping**.

This replaces the older Help Text mapping approach. All new installations use Advanced Mapping by default.

## Donation Matching

`GE_GiftEntryController` and the `geDonationMatching` component handle the UI-side of matching, allowing users to review and select from candidate matches. On the backend, `BDI_DonationMatcher` runs the matching logic:

- **Contact matching** — uses the configured `Contact_Matching_Rule__c` fields (name, email, etc.) to find an existing contact
- **Donation matching** — looks for existing Opportunities with a matching amount and close date within the configured date range
- **Manual override** — users can accept or reject suggested matches through the gift entry form

## Dry Run

Before finalizing a batch, users can run a dry run via the **Dry Run** button in the batch entry UI. This executes the full import logic without committing any DML, showing which records would succeed and which would fail along with the specific error messages. The dry run is powered by `GE_GiftEntryController.runBatchDryRun`.

## Allocations in Gift Entry

When Allocations are enabled, the gift entry form includes an allocation widget (`geFormWidgetAllocation`, `geFormWidgetRowAllocation`) that allows donors' gifts to be split across multiple General Accounting Units. Allocation percentages are validated to sum to 100% before the gift can be processed.

## Soft Credits in Gift Entry

The `geFormWidgetSoftCredit` and `geFormWidgetSoftCreditRow` components allow soft credit contact roles to be assigned during gift entry, attributing partial credit to secondary contacts.

## Gift Entry Settings

Settings are accessed through **NPPatch Settings > System Tools > Advanced Mapping** (for field mapping configuration) and through `Gift_Entry_Settings__c`:

| Setting | Purpose |
|---------|---------|
| `Default_Gift_Entry_Template__c` | Default form template used when no template is specified |
| `Enable_Gateway_Assignment__c` | Show payment gateway selector on the gift entry form |

## Key Apex Classes

**`GE_GiftEntryController`** — main Apex controller for the gift entry LWC; handles template loading, gift saving, batch processing, dry run execution, and lookup operations.

**`GiftBatchService`** / **`GiftService`** — service layer for batch and individual gift operations.

**`GiftBatch`** / **`Gift`** — domain objects representing a gift batch and an individual gift in processing.

**`GiftBatchSelector`** / **`GiftSelector`** — selectors for querying `DataImportBatch__c` and `DataImport__c` records.

**`GiftEntryProcessorQueue`** — queueable Apex that processes gifts asynchronously; `GiftEntryProcessorQueueFinalizer` handles post-processing cleanup.

**`GE_Template`** — server-side template loader and validator.

**`GE_LookupController`** — handles type-ahead lookup searches in the gift entry form.

**`GE_PaymentServices`** — handles payment gateway interactions if a gateway is configured.

**`GE_SettingsService`** — provides settings and permission checks to the gift entry UI.

**`BGE_FormTemplate_TDTM`** — trigger handler on Form_Template__c that prevents deletion of templates in use by active batches.

## Error Handling

Import errors are stored as messages on the `DataImport__c.FailureInformation__c` field, making them immediately visible to the user in the batch entry table. Errors that occur during asynchronous batch processing are also logged to `Error__c`.

## Integration Points

- **Contacts & Accounts** — found or created during import based on matching rules
- **Opportunities** — created or updated as the primary donation record
- **OppPayment__c** — optionally created when payment fields are populated
- **Allocations** — distributed across GAUs when the allocation widget is used
- **Campaigns** — linked to opportunities during import
- **Recurring Donations** — the gift entry form can create or update a recurring donation alongside a one-time gift (via `geModalRecurringDonation`)

---

*If you see something that could be improved, please create an issue or email admin@nppatch.com.*
