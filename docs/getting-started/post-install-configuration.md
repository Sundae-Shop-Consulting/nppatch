# Post-Install Configuration

After installing NPPatch, the package initializes a set of default settings automatically. This page describes what those defaults are and which settings you should review and adjust for your organization.

## How Settings Work in NPPatch

NPPatch uses Salesforce hierarchy custom settings to store its configuration. These settings can be configured at the org level (applied to everyone), at the profile level (applied to users with a specific profile), or at the individual user level.

The primary interface for managing these settings is the **NPPatch Settings** page, accessible from the App Launcher or the NPPatch Settings tab.

Under the hood, settings are managed through a centralized facade (`UTIL_CustomSettingsFacade`) that provides in-memory caching to minimize database queries. When you change a setting through the UI, it updates the corresponding custom setting record.

## Settings Initialized at Install

The following settings are created with default values when NPPatch is installed. Each section describes the default and when you might want to change it.

### Account Model

**Default:** Household Account model enabled.

NPPatch supports two account models for managing individual constituents:

- **Household Account Model** — each household gets a shared Account record; individual Contacts are associated with their household. This is the standard NPSP configuration and the default.
- **One-to-One Account Model** — each Contact gets their own individual Account record. This is an older model that some organizations still use.

!!! info "Account Model Implications"
    The account model affects how Contacts are organized, how donations roll up, and how household naming works. Changing this after data has been created requires careful migration planning.

### Household Naming

**Default:** Automatic household naming enabled.

When enabled, NPPatch automatically generates names for Household Account records based on the Contacts in the household. The naming format can be customized through the Household Naming Settings, which control the formal greeting, informal greeting, and household name format.

### Contacts & Organizations

**Default settings include:**

- Automatic payment creation: **Enabled** — when an Opportunity is created with a Closed Won stage, a Payment record is automatically created
- Opportunity Contact Roles: **Enabled** — automatic creation of Contact Roles on Opportunities
- Opportunity naming: configured but may need format customization

### Recurring Donations

**Default settings include:**

- Maximum donations per recurring donation: **50**
- Forecast months: **12**
- Close action for past-due installments: **Mark as Closed Lost**
- Batch sizes configured for processing

These defaults work well for most organizations. You may want to adjust the maximum donations count for organizations with very long-running recurring gifts, or change the close action behavior based on your organization's accounting practices.

### Allocations

**Default:** Allocations **disabled**.

The GAU (General Accounting Unit) Allocations feature allows organizations to split donation amounts across multiple funds or accounts. This is powerful but adds complexity, so it's disabled by default.

To enable allocations:

1. Open **NPPatch Settings**
2. Navigate to **Donations > Allocations**
3. Enable the feature
4. Configure a default General Accounting Unit if desired

### Customizable Rollups

**Default:** Customizable Rollups **disabled**.

Customizable Rollups (CRLP) replace the legacy rollup mechanism with a more flexible, metadata-driven approach. When disabled, NPPatch falls back to the legacy trigger-based rollups.

Most organizations should enable Customizable Rollups for better performance and flexibility:

1. Open **NPPatch Settings**
2. Navigate to **Customizable Rollups**
3. Enable the feature
4. Review and adjust the default rollup definitions

### Error Handling

**Default settings:**

- Error storage: **Enabled** — errors are stored in Error__c records
- Error notifications: **Enabled** — admin users receive notifications for errors
- Notification recipients: **All System Administrators**

### Affiliations

**Default:** Automatic affiliation creation **enabled**.

When a Contact is associated with an Organization Account, an Affiliation record is automatically created to track the relationship.

### Relationships

Relationship settings control the automatic creation and reciprocal tracking of relationships between Contacts. Defaults are configured for standard relationship types (spouse, parent/child, employer/employee, etc.).

## Trigger Handler Configuration

NPPatch uses the TDTM (Table-Driven Trigger Management) framework to manage all trigger-based automation. The default configuration includes 40+ trigger handlers covering all standard NPPatch functionality.

You can view and manage trigger handlers through:

1. **NPPatch Settings > System Tools > Trigger Handlers** — the settings UI
2. **Trigger_Handler__c records** — directly querying or viewing the custom object

Each handler can be individually enabled or disabled without modifying code. This is useful for troubleshooting or for temporarily disabling specific automation during data migrations.

See [Trigger Framework](../architecture/trigger-framework.md) for a complete reference of handlers and their purposes.

## Permission Setup

### The NPPatch_Admin Permission Set

The package includes a pre-built permission set (`NPPatch_Admin`) that grants full access to all NPPatch custom objects and fields. This permission set:

- Grants CRUD access to all NPPatch custom objects
- Grants read/write access to all custom fields (formula fields are read-only)
- Grants appropriate access to standard objects used by NPPatch (Account, Contact, Opportunity, Campaign, Lead, Case, Task)

Assign this to admin users and any users who need full access to NPPatch data.

### Creating Additional Permission Sets

For non-admin users, you'll likely want to create more restrictive permission sets. Common patterns:

- **Fundraiser**: Read/write on Opportunities, Payments, Recurring Donations; read on Accounts and Contacts
- **Data Entry**: Read/write on DataImport__c and DataImportBatch__c for batch gift entry; read on other objects
- **Read-Only**: Read access to all NPPatch objects for reporting users

## Recommended First Steps After Installation

1. **Review Account Model settings** — confirm the household or one-to-one model matches your organization's needs
2. **Enable Customizable Rollups** — unless you have a specific reason to use legacy rollups
3. **Review Recurring Donation settings** — adjust max donations and close behavior
4. **Assign the NPPatch_Admin permission set** to your admin users
5. **Create a test Contact** — verify that household creation, naming, and basic automation are working
6. **Create a test Opportunity** — verify that payments are created and rollups calculate correctly
7. **Review Trigger Handlers** — ensure all expected automation is active
8. **Set up Error Notifications** — confirm that error emails are routing to the right administrators

---

*This documentation was generated by AI and still needs human review. If you see something that could be improved, please create an issue or email admin@nppatch.com.*
