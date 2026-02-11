# Package Installation

This guide covers installing NPPatch from a published package version into a Salesforce org. This is the recommended path for consultants evaluating the package or deploying it to a client org.

## Prerequisites

Before installing NPPatch, confirm the following:

**Salesforce Edition.** NPPatch requires Enterprise Edition, Unlimited Edition, or Developer Edition. It will not install on Professional Edition or Group Edition orgs.

**API Version.** The target org must support Salesforce API version 63.0 or later.

**Admin Access.** You'll need System Administrator access to the target org to install the package.

**Existing NPSP Status.** If the target org already has the Salesforce-managed NPSP installed, read the [namespace implications](#installing-alongside-existing-npsp) section below before proceeding.

## Installation Steps

### Step 1: Get the Install Link

Package install links are published on the [NPPatch releases page](https://github.com/Sundae-Shop-Consulting/nppatch/releases). Each release includes:

- A production/developer install link
- A sandbox install link
- Release notes describing what changed

!!! tip "Start with a Sandbox"
    Always install in a sandbox or developer org first. Evaluate the package thoroughly before installing in a production environment.

### Step 2: Install the Package

1. Open the install link in a browser where you're logged into the target Salesforce org
2. If prompted, log in with System Administrator credentials
3. On the installation screen, choose who to install for:
    - **Install for Admins Only** — recommended for initial evaluation
    - **Install for All Users** — appropriate for production deployment after testing
    - **Install for Specific Profiles** — for controlled rollout
4. If prompted to approve third-party access, review and approve
5. Click **Install**

Installation typically takes 5-15 minutes depending on the org's complexity. You'll receive an email when installation is complete.

### Step 3: Assign Permissions

After installation, assign the **nppatch_Admin** permission set to users who need full access to NPPatch objects and fields.

1. Navigate to **Setup > Permission Sets**
2. Find **nppatch_Admin**
3. Click **Manage Assignments**
4. Add the appropriate users

The nppatch_Admin permission set grants read/write access to all NPPatch custom objects and fields. You may want to create additional permission sets with more limited access for non-admin users.

### Step 4: Configure Settings

After installation, NPPatch initializes default settings automatically. However, several settings should be reviewed and adjusted for your organization's needs. See the [Post-Install Configuration](post-install-configuration.md) guide for details.

## Installing Alongside Existing NPSP

If the target org already has the Salesforce-distributed NPSP managed package installed, be aware of the following:

**Different namespaces.** NPPatch uses the `nppatch` namespace while NPSP uses `npsp`. Both packages can technically coexist in the same org, but this is not a recommended configuration. You would end up with two parallel sets of custom objects, fields, and automation that could conflict.

**Not a direct upgrade.** Installing NPPatch does not upgrade or replace the existing NPSP installation. They are separate packages with separate namespaces.

**Recommended approach for existing NPSP orgs:**

1. Install NPPatch in a **sandbox** copy of the production org
2. Evaluate whether it meets the organization's needs
3. If proceeding, plan a data migration from `npsp__` objects and fields to `nppatch__` equivalents
4. Uninstall the original NPSP packages only after the migration is complete and validated

!!! warning "Data Migration Required"
    Moving from NPSP to NPPatch is a migration, not an upgrade. Plan for data mapping, field-level migration, workflow updates, and user retraining around the new namespace.

## Verifying the Installation

After installation completes:

1. **Check installed packages.** Navigate to **Setup > Installed Packages** and confirm NPPatch appears with the expected version number.

2. **Check custom objects.** Navigate to **Setup > Object Manager** and verify that NPPatch custom objects are present (they'll be prefixed with `nppatch__`), including: Recurring_Donation__c, Address__c, Allocation__c, General_Accounting_Unit__c, Relationship__c, and others.

3. **Check NPSP Settings.** Navigate to the **NPSP Settings** tab (if installed as a tab) or search for "NPSP Settings" in the App Launcher. The settings page should load and display the current configuration.

4. **Run a smoke test.** Create a test Contact and verify that a Household Account is automatically created (if household management is enabled in settings).

## Troubleshooting

**Installation fails with dependency errors.** NPPatch is self-contained and should not have external package dependencies. If you encounter dependency errors, confirm that no conflicting packages are installed and that the org meets the edition and API version requirements.

**Objects or fields are missing after installation.** Check that the nppatch_Admin permission set is assigned. Fields may be present but not visible without the appropriate permissions.

**Automation isn't firing.** NPPatch's trigger handlers are controlled by the TDTM framework and configured via Trigger_Handler__c records. Navigate to the Trigger Handler tab or query Trigger_Handler__c records to verify the handlers are active. See [Trigger Framework](../architecture/trigger-framework.md) for details.

## Uninstalling

To uninstall NPPatch:

1. Navigate to **Setup > Installed Packages**
2. Find **NPPatch** and click **Uninstall**
3. Follow the prompts to confirm

!!! danger "Uninstalling Deletes Data"
    Uninstalling the package will delete all data stored in NPPatch custom objects. Export any data you need to preserve before uninstalling.
