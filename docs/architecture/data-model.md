# Data Model

## Overview

nppatch extends Salesforce's standard objects (Account, Contact, Opportunity) with custom objects supporting nonprofit-specific features. The data model is designed for flexibility, supporting both household account models and traditional contact-centric approaches.

## Constituent Management

### Contact

The standard Contact object is extended with nonprofit-specific fields:

**Key Custom Fields:**
- `Preferred_Email__c` - Contact's preferred email address
- `Preferred_Phone__c` - Contact's preferred phone number
- `Preferred_Phone_Type__c` - Pickup list for phone type
- `Badge_IDs__c` - External IDs for matching/integration
- `Do_Not_Contact__c` - Checkbox flag for contact preferences
- `Do_Not_Phone__c` - Exclude from phone outreach
- `Do_Not_Email__c` - Exclude from email outreach
- `Do_Not_Mail__c` - Exclude from mailing lists

**Relationships:**
- Child records: Household__c, Relationship__c, Address__c
- Parent records: Account (for organizational relationships), Household__c

### Account

Standard Account object is configured with nonprofit extensions:

**Household Account Model Fields (when enabled via settings):**
- `RecordType` - Household Account record type
- `BillingAddress` - Household mailing address
- `SYSTEM_AccountType__c` - Account type classifier

**Organizational Account Fields:**
- Account Name - Organization name
- BillingAddress - Organization address
- Phone - Main phone
- Website - Organization website

**Key Features:**
- Supports both 1-to-1 (Contact parent) and household account models
- Configured via `Contacts_And_Orgs_Settings__c.Account_Processor__c`
- Can operate in either mode in same org

### Household__c

Groups related contacts for collective management and rollups.

**Fields:**
- `Name` (auto-number) - Household identifier
- `HouseholdPhone__c` - Primary contact number
- `HouseholdEmail__c` - Primary email address
- `Formula_MailingAddress__c` - Formatted mailing address
- `Always_Anonymous__c` - Privacy flag

**Relationships:**
- Parent Account (optional, via Account_Processor setting)
- Child Contacts (via Household__c lookup)

**Configuration:**
- Enabled/disabled via `Households_Settings__c.Household_Rules__c`
- Can run alongside Household Account model
- Named automatically using `Household_Naming_Settings__c`

### Address__c

Manages mailing addresses for both contacts and households, supporting seasonal addresses.

**Fields:**
- `MailingStreet__c` - Street address (supports two lines via MailingStreet2__c)
- `MailingCity__c` - City
- `MailingState__c` - State/Province
- `MailingPostalCode__c` - ZIP/Postal code
- `MailingCountry__c` - Country
- `Address_Type__c` - Pickup (Home, Work, Other)
- `Default_Address__c` - Checkbox for primary address
- `Exclude_from_Updates__c` - Prevents override during imports
- `Formula_MailingAddress__c` - Formatted display address
- `Geolocation__c` - Geo coordinates for mapping
- `API_Response__c` - Address verification API response
- `Ambiguous__c` - Flag for ambiguous verification results
- `Latest_Start_Date__c` - Seasonal address start date
- `Latest_End_Date__c` - Seasonal address end date
- `Administrative_Area__c` - Verified county/region
- `Congressional_District__c` - District identifier

**Relationships:**
- Parent Contact (via Contact field)
- Parent Account (via Account field)
- Parent Household (via Household_Account field)

**Verification:**
- Configured via `Addr_Verification_Settings__c`
- Supports automatic USPS verification
- Rejects ambiguous results if configured

### Relationship__c

Models bidirectional relationships between contacts (family, professional, social).

**Fields:**
- `Contact__c` - The primary contact
- `Related_Contact__c` - The related contact
- `Relationship_Type__c` - Type of relationship
- `ReciprocalType__c` - Opposite relationship type
- `Description__c` - Additional context
- `Status__c` - Active/Inactive status

**Features:**
- Reciprocal relationships automatically maintained
- One-way or two-way relationships supported
- Configured via `Relationship_Settings__c`
- Reciprocal method: 'List Setting' for flexible configuration

### Affiliation__c

Represents a contact's affiliation with an organization (employer, school, board membership).

**Fields:**
- `Contact__c` - Affiliated contact
- `Organization__c` - Organization account
- `Primary__c` - Marks primary affiliation
- `Status__c` - Active/Inactive
- `Role__c` - Role within organization
- `StartDate__c` - When affiliation began
- `EndDate__c` - When affiliation ended

**Features:**
- Automatic creation when Contact Account Name field populated
- Primary affiliation tracked for rollup calculations
- Configured via `Affiliations_Settings__c`

## Donations & Payments

### Opportunity

Standard Opportunity object extended for nonprofit donation tracking:

**Custom Fields:**
- `RecordType` - Donation, Grant, In-Kind, etc.
- `Amount` - Donation amount (extended with soft credit allocation)
- `StageName` - Pipeline stage
- `CloseDate` - Expected/actual close date
- `AccountId` - Donor account (if not contact-based)
- `ContactId` - Donor contact (if not account-based)
- `npe03__Account_Soft_Credit_Total__c` - Soft credit total amount
- `npe03__Contact_Soft_Credit_Total__c` - Contact soft credit total
- `Batch_Status__c` - Data import batch reference
- `Campaign` - Related campaign for tracking outreach

**Relationships:**
- Parent Account or Contact (via standard lookup)
- Child OppPayment__c records (payment schedule)
- Child Partial_Soft_Credit__c records (partial soft credits)
- Related Recurring_Donation__c
- Related General_Accounting_Unit__c (allocation)

### OppPayment__c

Represents a payment installment against an opportunity (pledge payment tracking).

**Fields:**
- `Opportunity__c` - Parent opportunity
- `Payment_Amount__c` - Amount of this payment
- `Payment_Date__c` - When payment was made
- `Payment_Method__c` - Payment method (check, card, ACH, etc.)
- `Paid__c` - Boolean indicating if paid
- `Comments__c` - Payment notes

**Configuration:**
- Enabled/disabled via `Contacts_And_Orgs_Settings__c.Payments_Enabled__c`
- Auto-close stage configurable via `Contacts_And_Orgs_Settings__c.Payments_Auto_Close_Stage_Name__c`

**Key Features:**
- Enables pledge tracking independent of opportunities
- Payment schedule can be defined via rollup
- Multiple payments against single opportunity

### Allocation__c

Distributes opportunity amounts across funds, cost centers, or grants (General Accounting Units).

**Fields:**
- `npe24__Opportunity__c` - Parent opportunity
- `npe24__General_Accounting_Unit__c` - Target fund/GAU
- `npe24__Amount__c` - Allocation amount
- `npe24__Percent__c` - Percentage of opportunity
- `npe24__Notes__c` - Allocation notes

**Features:**
- Multiple allocations per opportunity
- Amount or percentage-based allocation
- Configured via `Allocations_Settings__c`

### General_Accounting_Unit__c (GAU / Fund)

Represents a fund, cost center, or grant to track donations against.

**Fields:**
- `Name` - GAU name
- `npe24__Active__c` - Enable/disable flag
- `npe24__Average_Amount__c` - Rollup average
- `npe24__Count__c` - Rollup donation count
- `npe24__Description__c` - Purpose and details
- `npe24__Total_Allocations__c` - Rollup total

**Relationships:**
- Parent parent_account (optional)
- Child Allocation__c records

**Configuration:**
- Campaign allocations via settings
- Default allocation in `Allocations_Settings__c`

### Partial_Soft_Credit__c

Models partial soft credit allocation for opportunities (recognizing multiple contributors).

**Fields:**
- `npe03__Contact__c` - Contact receiving credit
- `npe03__Contact_Role_ID__c` - Opportunity contact role
- `npe03__Opportunity__c` - Parent opportunity
- `npe03__Amount__c` - Credit amount
- `npe03__Role_Name__c` - Role type (Soft Credit, Matched Donor, etc.)

**Features:**
- Enables recognition of non-primary donors
- Amount-based soft credit allocation
- Automatic creation from ContactRoles when configured
- Rollup to Contact and Account

### Account_Soft_Credit__c

Organization-level soft credit for opportunities.

**Fields:**
- `npe03__Account__c` - Organization receiving credit
- `npe03__Opportunity__c` - Parent opportunity
- `npe03__Amount__c` - Credit amount
- `npe03__Role_Name__c` - Credit role

**Purpose:**
- Track organizational soft credits
- Enable foundation/grant co-funder recognition
- Separate from contact-level soft credits

## Recurring Giving

### Recurring_Donation__c

Represents a committed series of donations from a donor.

**Fields:**
- `Name` - Auto-generated recurring donation identifier
- `Contact__c` - Donor contact
- `Organization__c` - Donor organization
- `npe03__Amount__c` - Amount per installment
- `npe03__Installment_Frequency__c` - Monthly, Quarterly, Annual, etc.
- `npe03__Installment_Period__c` - Frequency label
- `npe03__Installments__c` - Number of remaining installments
- `npe03__Total__c` - Total value of commitment
- `npe03__Open_Ended_Status__c` - Open-ended or closed
- `Date_Established__c` - Commitment start date
- `npe03__Recurring_Type__c` - Fixed or open-ended

**v2 Fields (RD2):**
- `Status__c` - Active/Lapsed/Closed
- `RecurringType__c` - Donation vs. Membership
- `InstallmentFrequency__c` - Monthly, Quarterly, etc.
- `StartDate__c` - When donations begin
- `EndDate__c` - When donations end
- `LeadDays__c` - Days before installment due

**Configuration:**
- Enabled via `Recurring_Donations_Settings__c.IsRecurringDonations2Enabled__c`
- Open opportunity behavior in `Open_Opportunity_Behavior__c`
- Batch size in `Recurring_Donation_Batch_Size__c`

### RecurringDonationSchedule__c

Tracks scheduled installment opportunities for a recurring donation.

**Fields:**
- `InstallmentNumber__c` - Sequence number
- `InstallmentAmount__c` - Amount for this installment
- `InstallmentDate__c` - Scheduled date
- `npe03__Opportunity__c` - Generated opportunity
- `Status__c` - Scheduled, Received, Skipped, etc.

**Purpose:**
- Forward-looking schedule of expected donations
- Enables forecasting
- Tracks which installments have been received

### RecurringDonationChangeLog__c

Audit trail of changes to recurring donations.

**Fields:**
- `Recurring_Donation__c` - Parent recurring donation
- `Field_Name__c` - What changed
- `OldValue__c` - Previous value
- `NewValue__c` - New value
- `ChangeType__c` - Type of change
- `CreatedDate` (standard) - When changed
- `CreatedById` (standard) - Who changed it

**Configuration:**
- Enabled via `Recurring_Donations_Settings__c.EnableChangeLog__c`

## Data Import

### DataImport__c

Staging table for importing constituent and donation data.

**Contact Fields:**
- `Contact_FirstName__c` - Contact first name
- `Contact_LastName__c` - Contact last name
- `Contact_Email__c` - Contact email
- `Contact_Phone__c` - Contact phone
- `Contact_Birthdate__c` - Contact birthdate

**Account Fields:**
- `Account1_Name__c` - Primary organization
- `Account1_City__c` - City
- `Account1_State_Province__c` - State
- `Account1_Street__c` - Street
- `Account1_Website__c` - Website
- `Account2_Name__c` - Secondary organization

**Donation Fields:**
- `Donation_Amount__c` - Donation amount
- `Donation_Date__c` - Donation date
- `Donation_Name__c` - Donation description
- `Donation_Stage__c` - Pipeline stage
- `Payment_Amount__c` - Payment amount
- `Payment_Date__c` - Payment date

**Matching Fields:**
- `Contact_Lookup__c` - Matched contact
- `Contact_Match_Exception__c` - Why match failed
- `Account1_Lookup__c` - Matched account
- `Donation_Lookup__c` - Matched opportunity

**Processing Fields:**
- `Status__c` - Imported, Failed, Processing, etc.
- `Batch__c` - Parent batch reference
- `Account1ImportStatus__c` - Account import result
- `Contact1ImportStatus__c` - Contact import result
- `DonationImportStatus__c` - Donation import result

**Configuration:**
- Field mapping via `Data_Import_Field_Mapping__mdt`
- Object mapping via `Data_Import_Object_Mapping__mdt`

### DataImportBatch__c

Batch container for import jobs.

**Fields:**
- `Name` - Batch identifier
- `Batch_Description__c` - Purpose and details
- `Batch_Status__c` - Open, Completed, Failed
- `npe03__Batch_Amount__c` - Total batch value
- `npe03__Batch_Number_of_Records__c` - Record count
- `npe03__Batch_Process_Size__c` - Batch size for processing
- `npe03__BDI_Lookup_ID__c` - Legacy field
- `Process_Using_Scheduled_Job__c` - Queue for async processing

**Configuration:**
- Batch size in `Data_Import_Settings__c.Batch_Size__c`
- Field mapping method in `Field_Mapping_Method__c`

## Engagement

### Engagement_Plan__c

Tracks a series of planned activities to accomplish a goal.

**Fields:**
- `Name` - Plan title
- `Account__c` - Parent account
- `Contact__c` - Primary contact
- `Description__c` - Plan details
- `Target_Account__c` - Account to which plan targets outreach
- `Target_Contact__c` - Contact to which plan targets outreach
- `Parent_Engagement_Plan__c` - If based on template
- `Start_Date__c` - Plan start date
- `End_Date__c` - Planned completion date
- `Status__c` - In Progress, Completed, Cancelled
- `Due_Date__c` - When plan should be completed

**Relationships:**
- Child Engagement_Plan_Task__c records
- Parent Engagement_Plan_Template__c (if instantiated from template)

### Engagement_Plan_Task__c

Individual activity within an engagement plan.

**Fields:**
- `Name` - Task title
- `Engagement_Plan__c` - Parent plan
- `Activity_Date__c` - Scheduled date
- `Type__c` - Task type (Call, Email, Meeting, etc.)
- `Subject__c` - Task summary
- `Description__c` - Task details
- `Assigned_To__c` - Owner user
- `Status__c` - Not Started, In Progress, Completed, Cancelled
- `ActivityTask__c` - Related Activity/Task

**Features:**
- Can be linked to platform tasks and activities
- Scheduled via engagement plan
- Tracks outreach execution

### Engagement_Plan_Template__c

Reusable template for engagement plans.

**Fields:**
- `Name` - Template name
- `Description__c` - Purpose and usage
- `Should_Create_Task__c` - Auto-create platform tasks
- `Skip_Day_Weekend__c` - Skip weekend days in scheduling
- `Active__c` - Enable/disable template

**Relationships:**
- Child Engagement_Plan_Task_Template__c records (task definitions)
- Child Engagement_Plan__c records (instantiated plans)

## System Objects

### Error__c

Audit trail of application errors and exceptions.

**Fields:**
- `Error_Type__c` - Exception type
- `Stack_Trace__c` - Full stack trace (long text)
- `Context_Type__c` - What was executing (Class, Trigger, Job, etc.)
- `Datetime__c` - When error occurred
- `Email_To__c` - Administrators notified
- `Error_Message__c` - User-facing message
- `Full_Message__c` - Technical details

**Configuration:**
- Enabled via `Error_Settings__c.Store_Errors_On__c`
- Notifications via `Error_Notifications_On__c`

### Trigger_Handler__c

Configuration table for TDTM trigger management.

**Fields:**
- `Name` - Handler name (e.g., "OppAfterInsert")
- `Class__c` - Handler class name (e.g., "OPP_OpportunityAfterInsert_TDTM")
- `Object__c` - Target object (e.g., "Opportunity")
- `Trigger_Action__c` - Multiple select: Before Insert, After Insert, etc.
- `Active__c` - Enable/disable handler
- `Asynchronous__c` - Run handler in future/batch context
- `Run_Order__c` - Numeric execution order
- `Description__c` - Handler purpose

### Level__c

Represents a donor or organizational level/classification.

**Fields:**
- `Name` - Level name (e.g., "Major Donor", "Prospect")
- `Target_Amount__c` - Minimum giving to qualify
- `Description__c` - Level criteria

**Used For:**
- Stewardship segmentation
- Reporting and analytics
- Assigned via Level_Assignment batch job

### Batch__c

Audit table for batch job execution.

**Fields:**
- `Name` - Job identifier
- `Status__c` - Completed, Failed, Processing
- `JobStartTime__c` - Execution start
- `JobEndTime__c` - Execution end
- `Records_Processed__c` - Count of processed records
- `Records_Failed__c` - Count of failures
- `Error_Notification__c` - Email notification sent

### Schedulable__c

Configuration for scheduled job execution.

**Fields:**
- `Name` - Job name
- `Class_Name__c` - Apex class to execute
- `Frequency__c` - Execution frequency
- `Last_Run__c` - Last execution timestamp
- `Next_Run__c` - Scheduled next run
- `Active__c` - Enable/disable

## Custom Settings Objects

nppatch uses 21 hierarchy custom settings for configuration:

| Setting | Purpose | Key Fields |
|---------|---------|-----------|
| `Contacts_And_Orgs_Settings__c` | Core constituent configuration | Account_Processor, Payments_Enabled, HH_Account_RecordTypeID |
| `Households_Settings__c` | Household processing | Household_Rules, Enable_Opp_Rollup_Triggers, Advanced_Household_Naming |
| `Recurring_Donations_Settings__c` | RD v1/v2 configuration | IsRecurringDonations2Enabled, Open_Opportunity_Behavior, Recurring_Donation_Batch_Size |
| `Relationship_Settings__c` | Relationship management | Reciprocal_Method |
| `Affiliations_Settings__c` | Affiliation processing | Automatic_Affiliation_Creation_Turned_On |
| `Error_Settings__c` | Error handling | Store_Errors_On, Error_Notifications_On, Error_Notifications_To |
| `Batch_Data_Entry_Settings__c` | Batch donation entry | Allow_Blank_Opportunity_Names, Opportunity_Naming |
| `Addr_Verification_Settings__c` | Address verification | Enable_Automatic_Verification, Reject_Ambiguous_Addresses |
| `Household_Naming_Settings__c` | Household naming | Household_Name_Format, Formal_Greeting_Format, Informal_Greeting_Format |
| `Allocations_Settings__c` | Allocation processing | Default_Allocations_Enabled, Payment_Allocations_Enabled |
| `Data_Import_Settings__c` | Data import configuration | Batch_Size, Contact_Matching_Rule, Donation_Matching_Behavior |
| `Customizable_Rollup_Settings__c` | CRLP configuration | Customizable_Rollups_Enabled, Rollups_Account_Batch_Size |
| `Levels_Settings__c` | Level assignment | Level_Assignment_Batch_Size |
| `Gift_Entry_Settings__c` | Modern gift entry | Default_Gift_Entry_Template, Enable_Gateway_Assignment |
| `Package_Settings__c` | Package metadata | Various internal settings |
| `Opportunity_Naming_Settings__c` | Opp naming | Naming format patterns |
| `Payment_Field_Mapping_Settings__c` | Payment field mapping | Field mappings |
| `User_Rollup_Field_Settings__c` | User-defined rollups | Rollup formulas |
| `Custom_Installment_Settings__c` | RD custom installments | Custom installment schedules |
| `Payment_Services_Configuration__c` | Payment gateway configuration | Gateway settings |
| (Legacy) `Addr_Verification_Settings__c` | Address verification (legacy) | Deprecated |

## Custom Metadata Types

nppatch includes 12+ custom metadata types for configuration:

| CMT | Purpose |
|-----|---------|
| `Data_Import_Object_Mapping__mdt` | Maps DataImport__c objects to Salesforce objects |
| `Data_Import_Field_Mapping__mdt` | Maps DataImport__c fields to Salesforce fields |
| `Data_Import_Field_Mapping_Set__mdt` | Named collections of field mappings |
| `Data_Import_Object_Mapping_Set__mdt` | Named collections of object mappings |
| `Rollup__mdt` | Customizable rollup definitions |
| `Filter_Rule__mdt` | Reusable filter conditions |
| `Filter_Group__mdt` | Groups of filter rules |
| `Opportunity_Stage_To_State_Mapping__mdt` | RD2 status mappings |
| `RecurringDonationStatusMapping__mdt` | RD2 status conversion |
| `Custom_Notification__mdt` | Custom notification definitions |
| `GetStartedChecklistItem__mdt` | Post-install checklist items |
| `GetStartedChecklistSection__mdt` | Checklist sections |

## Access Control

All custom objects use the following sharing models:

- **Read/Write**: Household, Address, Recurring_Donation, Engagement_Plan (user-level sharing enabled)
- **ControlledByParent**: OppPayment (shares with parent Opportunity)
- **Private**: Trigger_Handler (admin only)
- **Read**: Error, Level, Batch (read-only for audit trail)

Custom settings are user-scoped with org-level defaults.
