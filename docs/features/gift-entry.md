# Gift Entry & Data Import

The Gift Entry and Data Import system provides flexible mechanisms for capturing and processing donations into Salesforce. The system supports both single-gift entry through an intuitive form interface and bulk batch processing of multiple gifts, with configurable field mapping and data validation.

## Overview

Gift Entry consists of two complementary approaches:

1. **Single Gift Entry (GE)**: Form-based UI for entering one gift at a time with real-time validation
2. **Batch Gift Entry (BGE)**: Bulk processing of multiple gifts in a batch with template-driven mapping
3. **Data Import (BDI)**: Underlying engine that maps external data to Salesforce objects

The `GE_GiftEntryController` orchestrates the Gift Entry experience, while `BDI_DataImportService` and `BDI_MappingService` handle the data import logic.

## Gift Entry UI

### Single Gift Form

The `ge_GiftEntryForm` Lightning component provides:

- **Donor Selection**: Find or create contact/account
- **Gift Amount**: Enter donation amount
- **Gift Date**: Specify when the gift was received
- **Payment Method**: Select how the gift was paid (cash, check, credit card, etc.)
- **Custom Fields**: Additional fields based on organization configuration
- **Real-Time Validation**: Error checking as user enters data

### Gift Entry Controller Methods

`GE_GiftEntryController` exposes key endpoints:

| Method | Purpose |
|--------|---------|
| `addGiftTo(dataImportBatchId, inboundGift)` | Adds a single gift to batch |
| `getGiftBatchView(dataImportBatchId)` | Retrieves batch with all gifts |
| `getGiftView(dataImportId)` | Retrieves individual gift details |
| `getTemplateView(templateId)` | Loads gift entry form template |
| `saveGiftEntry(dataImportId, giftData)` | Saves gift and creates opportunity |

### Currency and Validation

The gift entry system:

- Validates multi-currency settings on the batch
- Enforces currency consistency within a batch
- Supports multi-currency donations if enabled

## Batch Gift Entry

### DataImportBatch__c

Batches group multiple gifts for cohesive processing:

| Field | Purpose |
|-------|---------|
| `Name__c` | Descriptive batch name |
| `Status__c` | Draft, Processing, Completed, Failed |
| `Batch_Description__c` | User notes about batch |
| `Date_Expected__c` | When batch was received/expected |
| `Active_Fields__c` | JSON of enabled field mappings |
| `Batch_Process_Size__c` | Number of records to process per batch job |

### DataImport__c

Individual gift records within a batch:

| Field | Purpose |
|-------|---------|
| `NPPatch_Data_Import_Batch__c` | Reference to parent batch |
| `Status__c` | Draft, Imported, Failed, Dry Run |
| `Contact_Firstname__c` | Donor first name |
| `Contact_Lastname__c` | Donor last name |
| `Contact_Email__c` | Donor email |
| `Contact_Phone__c` | Donor phone |
| `Donation_Amount__c` | Gift amount |
| `Donation_Date__c` | Gift date |
| `Donation_Record_Type_Name__c` | Opportunity record type |
| `Payment_Amount__c` | Payment amount (if different from donation) |
| `Payment_Method__c` | How gift was received |

### Batch Processing

The `BDI_DataImportBatch_TDTM` trigger handler:

1. Validates batch before processing
2. Queues batch for async processing via batch job
3. Prevents modification of batch while processing

## Template Builder

The template builder enables organizations to create custom gift entry forms:

### Form_Template__c

Configuration for gift entry forms:

| Field | Purpose |
|-------|---------|
| `Name` | Template display name |
| `Description__c` | Usage notes |
| `Template_JSON__c` | Configuration (sections, fields, validation) |
| `Is_Default__c` | Whether this is default for new entries |

### Template Features

- **Sections**: Group related fields (donor info, gift details, payment info)
- **Field Selection**: Choose which fields appear on form
- **Field Ordering**: Define field display sequence
- **Required Fields**: Mark fields that must be completed
- **Field Labels**: Customize field labels for form
- **Help Text**: Add field-level guidance

### GE_Template Class

Server-side template service providing:

- Template loading and caching
- Template validation
- Field availability checking
- Permission evaluation for fields

## Data Import Engine

### BDI_DataImportService

Core service for importing DataImport records into opportunities and payments:

```apex
BDI_DataImportService service = new BDI_DataImportService();
service.importRecords(dataImportRecordIds);
```

The service:

1. **Validation**: Checks required fields and data types
2. **Mapping**: Transforms DataImport fields to Opportunity/Payment fields
3. **Matching**: Finds existing contacts/accounts or creates new ones
4. **DML**: Inserts/updates opportunities and related records
5. **Error Handling**: Logs errors to Error__c for user review

### BDI_MappingService

Advanced field mapping configuration through custom metadata:

#### Mapping Configuration

`BDI_Mapping__mdt` custom metadata type defines:

- **Data Import Field**: Source field on DataImport__c
- **Salesforce Object**: Target object (Opportunity, Contact, Account)
- **Salesforce Field**: Target field on object
- **Data Type**: How to transform the value (String, Decimal, Date, etc.)
- **Transform Logic**: Optional Apex class for complex transformations

#### Predefined Mappings

Standard mappings for common scenarios:

| DataImport Field | Target | Purpose |
|------------------|--------|---------|
| `Contact_Firstname__c` | Contact.FirstName | Donor first name |
| `Contact_Lastname__c` | Contact.LastName | Donor last name |
| `Contact_Email__c` | Contact.Email | Donor email |
| `Donation_Amount__c` | Opportunity.Amount | Gift amount |
| `Donation_Date__c` | Opportunity.CloseDate | Opportunity close date |

#### Advanced Mapping

`BDI_MappingServiceAdvanced` extends mapping with:

- Custom object mappings (GAU allocations)
- Dependent field logic
- Conditional transformations
- Multi-field aggregations

### Donation Matching

`BDI_DonationSelector` and matching logic identifies existing donations to avoid duplicates:

- **Donor Matching**: Find or create contact/account based on name/email
- **Duplicate Prevention**: Check for existing opportunities with same amount/date
- **Soft Matching**: Fuzzy matching on names for data quality
- **Account Creation**: Auto-create accounts from organization data

## Field Mapping via Custom Metadata

### BDI_Mapping__mdt

Organizations can configure custom field mappings:

**Example: Adding a custom campaign source field**

```
Mapping: CustomCampaignSource__c → Opportunity.CampaignId
Data Type: Lookup
Transform: Campaign name to ID lookup
```

**Example: Custom mapping with formula**

```
Mapping: DonorType__c → Account.SYSTEM_AccountType__c
Data Type: String
Transform: Map "Individual" → "Individual Account", "Organization" → "Organization Account"
```

### Mapping Validation

Before import, the system validates:

- Required fields are populated
- Data types match target fields
- Lookup references exist
- Custom object access is available

## Allocations in Gift Entry

### GAU Allocation Support

When allocations are enabled, gift entry supports:

- **Primary Allocation**: Associate gift with one General Accounting Unit (fund)
- **Multi-Allocation**: Split gift across multiple GAUs with percentages
- **Default Allocations**: Auto-apply predefined allocation splits

The `BDI_CustObjMappingGAUAllocation` class handles:

- Mapping DataImport allocation fields to Allocation__c records
- Validating allocation percentages sum to 100%
- Creating allocations during import

## Dry Run Processing

Before final import, users can execute dry runs:

1. **Dry Run Validation**: All validation runs without creating records
2. **Error Preview**: Shows which records would fail
3. **Record Preview**: Displays what would be created
4. **Confirmed Import**: User reviews and confirms before actual import

## Data Quality and Error Handling

### Error Logging

Import errors are logged to `Error__c`:

| Field | Purpose |
|-------|---------|
| `Record_ID__c` | ID of problematic DataImport record |
| `Error_Type__c` | Validation, mapping, DML error, etc. |
| `Full_Message__c` | Complete error details |
| `Stack_Trace__c` | Apex stack trace for debugging |

### Validation Errors

Common validation failures:

- Required fields missing
- Invalid email formats
- Amount as non-numeric
- Unknown payment methods
- Closed date in past

### DML Errors

During record creation:

- Duplicate rule violations
- Field validation rule failures
- Foreign key violations
- Permission errors

## GE_SettingsService

Configuration and permissions management:

- Gift Entry enablement check
- User permission validation
- Setting retrieval (batch size, default record type, etc.)
- Feature flag checking

## Gift Entry Permissions

The system requires:

- Read/Write on Contact
- Read/Write on Opportunity (or custom donation object)
- Read/Write on DataImport__c
- Read/Write on OppPayment__c (if payments enabled)
- Read on Account (for matching)

## Integration Points

- **Contacts & Accounts**: Finds or creates donors during import
- **Opportunities**: Creates donation opportunities
- **Payments**: Optionally creates payment records for split payment scenarios
- **Allocations**: Distributes gift amounts across funds/GAUs
- **Campaigns**: Links opportunities to campaigns
- **Custom Objects**: Supports mapping to custom donation objects

## Use Cases

**Event Gift Collection**: Import gifts collected at fundraising events using batch processing with event-specific template.

**Grant Processor Workflow**: Data import with pre-configured field mappings for specific grant donor formats.

**Online Giving Integration**: Automated import of gifts from donor portal or third-party platform via API.

**Offline Gift Processing**: Staff enters gifts via form with real-time validation and auto-saves to batch.

**Duplicate Prevention**: Data import matching logic prevents recording same gift multiple times.

**Multi-Fund Giving**: Gift entry template includes allocation fields for donors splitting gifts across multiple funds.

---

*This documentation was generated by AI and still needs human review. If you see something that could be improved, please create an issue or email admin@nppatch.com.*
