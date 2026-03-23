# Data Model

## Overview

NPPatch extends Salesforce's standard objects (Account, Contact, Opportunity) with custom objects supporting nonprofit-specific features. The data model is designed for flexibility, supporting both household account models and traditional contact-centric approaches.

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
- Supports address verification via Google or Cicero APIs (requires a user-provided API key)
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

Represents an ongoing donation commitment from a contact or organization.

**Key Fields:**
- `Name` - Auto-generated identifier
- `Contact__c` - Donor contact (for individual donors)
- `Organization__c` - Donor organization (for organizational donors)
- `Amount__c` - Amount per installment
- `Installment_Period__c` - How often installments occur (Monthly, Quarterly, Annually, Weekly, etc.)
- `Installment_Frequency__c` - Number of installments per period
- `Day_of_Month__c` - For monthly/quarterly schedules, the day each installment falls
- `StartDate__c` - When donations begin
- `EndDate__c` - Optional end date
- `Status__c` - Active, Lapsed, Closed, Paused (or custom values via status mapping)
- `RecurringType__c` - Fixed or Open (variable amount)
- `Planned_Installments__c` - Total expected installment count; null means open-ended

**Configuration:**
- Open opportunity behavior in `Recurring_Donations_Settings__c.Open_Opportunity_Behavior__c`
- Batch size in `Recurring_Donations_Settings__c.Recurring_Donation_Batch_Size__c`
- Status automation in `StatusAutomationDaysForLapsed__c` / `StatusAutomationDaysForClosed__c`

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
- Batch process size in `Batch_Process_Size__c` field on the batch record
- Field mapping via `Data_Import_Field_Mapping__mdt` and `Data_Import_Object_Mapping__mdt` custom metadata

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

## Program Management

NPPatch includes the Program Management Module (PMM), providing program and service delivery tracking alongside fundraising.

### Program__c

Represents a program offered by the organization.

**Fields:**
- `Name` - Program name
- `Description__c` - Program description
- `ShortSummary__c` - Brief summary
- `StartDate__c` - Program start date
- `EndDate__c` - Program end date
- `ProgramIssueArea__c` - Issue area classification
- `Status__c` - Active, Completed, Planned, etc.

**Relationships:**
- Child ProgramCohort__c records (cohorts within the program)
- Child ProgramEngagement__c records (participant enrollments)
- Child Service__c records (services offered under the program)

### ProgramCohort__c

Groups participants within a program for tracking and reporting.

**Fields:**
- `Name` - Cohort name
- `Program__c` - Parent program
- `Description__c` - Cohort details
- `StartDate__c` - Cohort start date
- `EndDate__c` - Cohort end date
- `Status__c` - Active, Completed, Planned

### ProgramEngagement__c

Tracks a contact's participation in a program.

**Fields:**
- `Name` - Engagement name
- `Contact__c` - Participating contact
- `Account__c` - Related account
- `Program__c` - Parent program
- `ProgramCohort__c` - Assigned cohort
- `Stage__c` - Enrollment stage (Applied, Enrolled, Active, Completed, Withdrawn)
- `Role__c` - Participant's role (Client, Volunteer, Service Provider)
- `ApplicationDate__c` - Date of application
- `StartDate__c` - Engagement start date
- `EndDate__c` - Engagement end date

### Service__c

A specific service offered under a program.

**Fields:**
- `Name` - Service name
- `Program__c` - Parent program
- `Description__c` - Service description
- `Status__c` - Active, Inactive
- `UnitOfMeasurement__c` - How service is measured (Hours, Sessions, Units)

**Relationships:**
- Child ServiceSchedule__c records
- Child ServiceDelivery__c records

### ServiceSchedule__c

Defines a recurring schedule for delivering a service.

**Fields:**
- `Name` - Schedule name
- `Service__c` - Parent service
- `FirstSessionStart__c` - First session start date/time
- `FirstSessionEnd__c` - First session end date/time
- `Frequency__c` - How often sessions repeat (Daily, Weekly, Monthly)
- `Interval__c` - Interval between sessions
- `DaysOfWeek__c` - Which days sessions occur
- `NumberOfServiceSessions__c` - Total sessions to generate
- `ParticipantCapacity__c` - Maximum participants
- `DefaultServiceQuantity__c` - Default quantity per delivery
- `PrimaryServiceProvider__c` - Primary staff contact
- `OtherServiceProvider__c` - Secondary staff contact

### ServiceSession__c

An individual occurrence of a scheduled service.

**Fields:**
- `Name` - Session name
- `ServiceSchedule__c` - Parent schedule
- `SessionStart__c` - Session start date/time
- `SessionEnd__c` - Session end date/time
- `Status__c` - Pending, Complete, Canceled
- `PrimaryServiceProvider__c` - Staff delivering the session
- `OtherServiceProvider__c` - Additional staff

### ServiceParticipant__c

Enrolls a contact in a service schedule.

**Fields:**
- `Name` - Participant name
- `Contact__c` - Participating contact
- `ProgramEngagement__c` - Related program engagement
- `Service__c` - Parent service
- `ServiceSchedule__c` - Enrolled schedule
- `SignUpDate__c` - Date of enrollment
- `Status__c` - Enrolled, Withdrawn, Completed

### ServiceDelivery__c

Records actual delivery of a service to a participant.

**Fields:**
- `Name` - Delivery name
- `Contact__c` - Recipient contact
- `Account__c` - Related account
- `Service__c` - Service delivered
- `ServiceSession__c` - Related session
- `ProgramEngagement__c` - Related engagement
- `Service_Provider__c` - Staff who delivered
- `DeliveryDate__c` - Date of delivery
- `Quantity__c` - Amount delivered
- `AttendanceStatus__c` - Present, Absent, Excused
- `AutonameOverride__c` - Custom name override

**Features:**
- Rollups to Contact, ProgramEngagement, Service, and ServiceSchedule
- Batch rollup processing via `ServiceDeliveryRollupsBatch`
- Trigger-driven updates via `ServiceDeliveryTriggerHandler`

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

NPPatch uses 21 custom settings for configuration — 13 hierarchy custom settings (supporting org-level defaults with optional user-level overrides) and 8 list custom settings (key-value configuration data). Administrators manage these through the **NPPatch Settings** page, not the standard Custom Settings page in Setup.

### Hierarchy Custom Settings (13)

| Setting | Purpose | Key Fields |
|---------|---------|-----------|
| `Contacts_And_Orgs_Settings__c` | Core constituent configuration | Account_Processor, Payments_Enabled, HH_Account_RecordTypeID |
| `Households_Settings__c` | Household processing | Household_Rules, Enable_Opp_Rollup_Triggers, Advanced_Household_Naming |
| `Recurring_Donations_Settings__c` | Recurring donation behavior | Open_Opportunity_Behavior, Recurring_Donation_Batch_Size, EnableChangeLog |
| `Relationship_Settings__c` | Relationship management | Reciprocal_Method |
| `Affiliations_Settings__c` | Affiliation processing | Automatic_Affiliation_Creation_Turned_On |
| `Error_Settings__c` | Error handling | Store_Errors_On, Error_Notifications_On, Error_Notifications_To |
| `Addr_Verification_Settings__c` | Address verification | Enable_Automatic_Verification, Reject_Ambiguous_Addresses |
| `Household_Naming_Settings__c` | Household naming | Household_Name_Format, Formal_Greeting_Format, Informal_Greeting_Format |
| `Allocations_Settings__c` | Allocation processing | Default_Allocations_Enabled, Payment_Allocations_Enabled |
| `Customizable_Rollup_Settings__c` | CRLP rollup engine | Rollups_Account_Batch_Size, Rollups_Limit_on_Attached_Opps_for_Skew |
| `Levels_Settings__c` | Level assignment | Level_Assignment_Batch_Size |
| `Gift_Entry_Settings__c` | Gift entry configuration | Default_Gift_Entry_Template |
| `Package_Settings__c` | Internal package metadata | Protected visibility — not exposed in the settings page |

### List Custom Settings (8)

| Setting | Purpose |
|---------|---------|
| `Opportunity_Naming_Settings__c` | Opportunity naming format patterns |
| `Payment_Field_Mapping_Settings__c` | Maps Opportunity fields to OppPayment__c fields during auto-creation |
| `User_Rollup_Field_Settings__c` | User-defined rollup field definitions |
| `Custom_Installment_Settings__c` | Custom installment periods for recurring donations |
| `Custom_Field_Mapping__c` | Maps Recurring Donation fields to Opportunity fields |
| `Custom_Column_Header__c` | Gift Entry landing page list view column configuration |
| `Relationship_Sync_Excluded_Fields__c` | Fields excluded from reciprocal relationship sync |

## Custom Metadata Types

NPPatch includes 12+ custom metadata types for configuration:

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

---

*If you see something that could be improved, please create an issue or email admin@nppatch.com.*
