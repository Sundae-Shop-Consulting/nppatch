# Issue: Consolidate Namespace References Before Launch

## Summary

The `nppatch` namespace is a placeholder used during 2GP development. Before launch, this will be replaced with the final namespace. We need to audit the codebase for hardcoded namespace references that won't automatically update when the namespace changes.

## Background

The codebase uses several patterns for namespace handling:

### Properly Tokenized (Will Auto-Update)
- **Metadata tokens**: `%%%NAMESPACE%%%` in field references, record type picklist mappings, etc.
- **Apex runtime methods**: `UTIL_Namespace.StrTokenNSPrefix()`, `UTIL_Namespace.StrAllNSPrefix()`, `UTIL_Namespace.getNamespace()`

### Potentially Hardcoded (Needs Audit)
- **Help text**: Field help text may contain hardcoded references like `Contact1.nppatch__AlternateEmail__c`
- **Custom labels**: Error messages or UI text referencing field API names
- **Validation rules**: Formula references in validation rule error messages
- **Flow metadata**: Field references in flows, process builders
- **Reports/Dashboards**: Filter criteria, column references
- **Custom metadata records**: Field mappings, rollup definitions

## Areas to Audit

### High Priority
- [ ] `DataImport__c` field help text (we removed some, but verify no `nppatch__` references remain)
- [ ] Custom labels in `CustomLabels.labels-meta.xml`
- [ ] Validation rule error messages
- [ ] Any remaining inline help text on custom fields

### Medium Priority
- [ ] Report filter criteria and formulas
- [ ] Dashboard components
- [ ] Email templates
- [ ] Flow field references and error messages

### Lower Priority (Less Likely)
- [ ] Apex string literals (should use UTIL_Namespace methods)
- [ ] Test assertions comparing field names
- [ ] Comments and documentation

## Search Commands

```bash
# Find potential hardcoded namespace references
grep -r "nppatch__" force-app/ --include="*.xml" --include="*.cls"

# Find help text that might have field references
grep -r "<inlineHelpText>" force-app/ -A 1

# Find custom label values with field-like patterns
grep -r "__c" force-app/main/default/labels/
```

## Acceptance Criteria

- [ ] No hardcoded `nppatch__` references in metadata or code
- [ ] All field references use namespace tokens or runtime methods
- [ ] Document any exceptions that intentionally reference the namespace

## Preliminary Findings

Quick grep for `nppatch` shows only one reference - a comment in `REL_Relationships_TEST.cls` explaining 2GP context. No hardcoded `nppatch__` field references found. This is encouraging but a thorough audit should still be done before namespace change.

## Notes

- The `%%%NAMESPACE%%%` token is replaced at deployment time by CumulusCI
- `%%%NAMESPACED_ORG%%%` is another token used in some contexts
- When changing namespace, also update `sfdx-project.json` and `cumulusci.yml`
