# ADR-0005: Org-Dependent Unlocked Package

**Status:** Accepted
**Date:** 2026-02-11

## Context

When creating a 2GP Unlocked package, there are two packaging modes:

1. **Fully Independent Package**: All dependencies must be explicitly declared and packaged. The package includes everything needed to install in a clean org.

2. **Org-Dependent Package**: The package can reference metadata that already exists in the target org without packaging it. Dependencies are resolved at install time from the org.

Our package (spinoff/NPPatch) consolidates NPSP component packages that were originally designed for 1GP. These packages make extensive use of:

- Standard objects and fields (Account, Contact, Opportunity, Campaign)
- Standard picklist values (Opportunity Stages, Contact Roles)
- Schema describe calls that expect certain metadata to exist
- Cross-object relationships and lookups

Attempting to package all of this as a fully independent 2GP package would require:
- Packaging StandardValueSets (destructive operation - see ADR-0001)
- Resolving all implicit dependencies on standard Salesforce metadata
- Potentially duplicating metadata that already exists in subscriber orgs

## Decision

Configure the package as **org-dependent** using:

```yaml
# cumulusci.yml
create_package_version:
    options:
        org_dependent: True
```

## Consequences

### Positive

- **Avoids StandardValueSet conflicts**: We don't need to package OpportunityStage, ContactRole, or other StandardValueSets that would overwrite subscriber values
- **Simpler dependency management**: Standard Salesforce metadata is assumed to exist rather than explicitly packaged
- **Smaller package footprint**: Only custom metadata is packaged; standard objects are referenced from the org
- **Flexibility for subscribers**: Subscribers can customize standard metadata without package conflicts
- **Faster package builds**: Less metadata to validate and package

### Negative

- **Org prerequisites required**: Target orgs must have certain metadata configured before installation:
  - Recommended Opportunity stages (Pledged, Promised, etc.)
  - Contact roles for soft credits (Soft Credit, Solicitor, Household Member, etc.)
  - Any other StandardValueSet values the package references
- **Installation may fail in bare orgs**: Installing in a brand-new org without configuration may cause errors if expected metadata is missing
- **Harder to test in isolation**: Build orgs must be configured with prerequisites before package validation

### Mitigations

1. **Build org configuration**: Use CumulusCI Metadata ETL tasks to configure build org prerequisites:
   ```yaml
   setup_build_org:
       steps:
           1: add_opportunity_stages  # Adds Pledged, Promised
           2: add_ocr_roles           # Adds Soft Credit, Solicitor, etc.
           3: deploy_pre              # Deploy record types, etc.
   ```

2. **Installation documentation**: Document required org configuration for subscribers

3. **Pre-install validation**: Consider adding a pre-install check that validates org prerequisites (future enhancement)

4. **Post-install configuration**: Provide CumulusCI flows or scripts for subscribers to configure their orgs

## Alternatives Considered

### Fully Independent Package
Rejected because:
- Would require packaging StandardValueSets (destructive)
- Would significantly increase package complexity
- Would conflict with subscriber customizations

### Managed Package (2GP Managed)
Not applicable for this use case:
- Original NPSP packages were 1GP managed
- Converting to 2GP managed would require different migration path
- Unlocked allows more flexibility for customization

## References

- [Salesforce: Org-Dependent Unlocked Packages](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_org_dependent.htm)
- ADR-0001: Use Standard Stages for Business Processes
- CumulusCI: Metadata ETL for StandardValueSets
