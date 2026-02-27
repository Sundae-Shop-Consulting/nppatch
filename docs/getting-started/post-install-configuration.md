# Post-Install Configuration

After installing NPPatch, the package initializes a set of default settings automatically. This page describes those defaults and which settings you'll want to review for your organization.

## How Settings Work in NPPatch

NPPatch stores its configuration in Salesforce hierarchy custom settings. Hierarchy custom settings can be configured at the org level (applies to everyone) or overridden at the profile or individual user level.

The primary interface for managing these settings is the **NPPatch Settings** page, accessible from the App Launcher or the NPPatch Settings tab. This UI organizes all configuration options into a structured navigation panel. Changes made here are saved immediately to the underlying custom setting records.

Avoid editing NPPatch custom settings directly through **Setup > Custom Settings**—while technically possible, it bypasses the validation and initialization logic in the settings UI.

## What's Enabled Out of the Box

Several features are fully enabled and ready to use immediately after installation, with no additional configuration steps:

- **Gift Entry** — the full Gift Entry and Batch Gift Entry experience is available from the Gift Entry tab without any enablement step
- **Customizable Rollups** — the CRLP rollup engine runs by default and ships with 86 pre-configured rollup definitions covering standard donor statistics fields. No "enable" step is required.
- **Enhanced Recurring Donations** — RD2 is the only recurring donations engine in NPPatch. There is no legacy mode to migrate from.
- **Advanced Mapping** — the Metadata-based field mapping engine for Gift Entry / Data Import is always active

## Settings Initialized at Install

The install script (`STG_InstallScript`) creates default custom setting records for all NPPatch settings objects if they don't already exist. The following sections describe the defaults you're most likely to want to review.

### Account Model

**Default:** Household Account model.

NPPatch supports two account models for managing individual constituents:

- **Household Account Model** — each household gets a shared Account record; individual Contacts are associated with their household. This is the default.
- **One-to-One Account Model** — each Contact gets their own individual Account record. This is an older model that some organizations still use.

!!! warning "Account Model is Not Easily Changed"
    The account model affects how Contacts are organized, how donations roll up, and how household naming works. Changing this setting after data has been created requires careful migration planning. Choose the right model before entering data.

Configure this in **NPPatch Settings > People > Account Model**.

### Household Naming

**Default:** Automatic household naming enabled.

When enabled, NPPatch automatically generates names, formal greetings, and informal greetings for Household Account records based on the Contacts in the household. The naming formats can be customized in **NPPatch Settings > People > Households**.

### Payments

**Default:** Payment creation enabled.

When an Opportunity is created, a corresponding `OppPayment__c` record is automatically created. This enables pledge tracking and payment reconciliation. Configure this in **NPPatch Settings > Donations > Payments**.

### Recurring Donations

**Default settings:**

- Maximum installments generated per RD: **50**
- Forecast months: **12**
- Close action for open installments when RD is closed: **Mark as Closed Lost**
- Batch sizes configured for standard processing

These defaults work well for most organizations. Adjust them in **NPPatch Settings > Recurring Donations**. You may want to change the close action behavior based on your organization's accounting practices, or adjust the forecast window if your major gift officers need longer visibility.

### Allocations

**Default:** Allocations disabled.

The GAU (General Accounting Unit) Allocations feature allows organizations to split donation amounts across multiple funds or accounts. It's powerful but adds complexity, so it's off by default.

To enable: **NPPatch Settings > Donations > Allocations**, then toggle Allocations on and optionally configure a default General Accounting Unit.

### Error Handling

**Default settings:**

- Error storage: **Enabled** — errors are written to `Error__c` records
- Error notifications: **Enabled** — system administrators receive email notifications for errors
- Notification recipients: **All System Administrators**

Review the notification recipient setting if you want errors routed to a specific admin or role rather than all system admins. Configure in **NPPatch Settings > System Tools > Error Notifications**.

### Affiliations

**Default:** Automatic affiliation creation enabled.

When a Contact is associated with an Organization Account, an `Affiliation__c` record is automatically created to track the relationship. Configure in **NPPatch Settings > Relationships > Affiliations**.

## Trigger Handler Configuration

NPPatch uses TDTM (Table-Driven Trigger Management) for all automation. The default configuration includes 40+ trigger handlers covering all standard NPPatch functionality.

You can view and manage trigger handlers through **NPPatch Settings > System Tools > Trigger Configuration**. Each handler can be individually enabled or disabled without modifying code. This is useful for troubleshooting or temporarily disabling specific automation during data migrations.

See [Trigger Framework](../architecture/trigger-framework.md) for a full reference.

## Permission Setup

### The NPPatch Permission Sets

The package includes permission sets for common roles. Assign the appropriate set to each user based on their responsibilities. At minimum, assign a permissions set with CRUD access to all NPPatch custom objects and fields to your admin users.

### Creating Additional Permission Sets

For non-admin users, create more restrictive permission sets based on their needs:

- **Fundraiser** — read/write on Opportunities, Payments, Recurring Donations; read on Accounts and Contacts
- **Gift Entry staff** — read/write on DataImport__c and DataImportBatch__c; read on other objects
- **Read-only** — read access to all NPPatch objects for reporting users

## Recommended First Steps After Installation

1. **Review Account Model** — confirm the household or one-to-one model matches your organization's needs before entering data
2. **Assign permission sets** to your admin and staff users
3. **Create a test Contact** — verify that household creation, naming, and basic automation are working
4. **Create a test Opportunity** — verify that payments are created and rollups calculate correctly on the Account and Contact
5. **Review Trigger Handlers** — confirm all expected automation is active in **NPPatch Settings > System Tools > Trigger Configuration**
6. **Configure Error Notifications** — verify error emails are routing to the right administrators
7. **Set Recurring Donation defaults** — adjust the close action and forecast window for your organization's practices
8. **Enable Allocations** if your organization tracks restricted or designated gifts across multiple funds

---

*If you see something that could be improved, please create an issue or email admin@nppatch.com.*
