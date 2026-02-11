# Issue: Support Dynamic Product Name Injection

## Summary

Enable dynamic injection of the product name throughout the codebase to support:
1. Rebranding from "NPSP" / "Nonprofit Success Pack" to the new product name
2. Easy forking and rebranding by other organizations

## Current State

The product name is hardcoded throughout the codebase in:
- Custom labels (settings pages, error messages, help text)
- Visualforce page titles and headings
- Lightning component labels
- Apex exception messages and logging
- Documentation strings and comments
- Custom object/field descriptions

### Examples of Hardcoded References
```
"NPSP Settings"
"Nonprofit Success Pack"
"NPSP Data Import"
"NPSP Batch Gift Entry"
```

## Proposed Solution

### Option A: Token Replacement (Build-Time)

Create a CCI task that performs token replacement during build/deployment:

```yaml
# cumulusci.yml
tasks:
  inject_product_name:
    class_path: tasks.InjectProductName
    options:
      product_name: "nppatch"
      product_name_short: "HW"
      token: "%%%PRODUCT_NAME%%%"
```

**Tokens:**
- `%%%PRODUCT_NAME%%%` → "nppatch" (or full name)
- `%%%PRODUCT_NAME_SHORT%%%` → "HW" (or abbreviation)
- `%%%PRODUCT_NAME_SETTINGS%%%` → "nppatch Settings"

### Option B: Custom Setting/Label (Runtime)

Store product name in a hierarchical custom setting or protected custom label, referenced at runtime:

```apex
String productName = ProductBranding__c.getInstance().Name__c;
// or
String productName = System.Label.ProductName;
```

**Pros:** No build task needed, can be changed post-install
**Cons:** More code changes, slight runtime overhead

### Option C: Hybrid Approach

- Use tokens for static metadata (page titles, field descriptions)
- Use custom setting for runtime strings (error messages, dynamic UI)

## Areas Requiring Updates

### High Volume
- [ ] Custom labels containing "NPSP" or "Nonprofit Success Pack"
- [ ] Visualforce page titles and static text
- [ ] Lightning component labels and help text
- [ ] Settings page headers and descriptions

### Medium Volume
- [ ] Custom object and field descriptions
- [ ] Apex error messages and logging
- [ ] Email templates
- [ ] Help text on fields

### Low Volume
- [ ] Report and dashboard names/descriptions
- [ ] Permission set descriptions
- [ ] App and tab labels

## Search Commands

```bash
# Find NPSP references in labels
grep -ri "npsp\|nonprofit success pack" force-app/main/default/labels/

# Find in Apex
grep -ri "npsp\|nonprofit success pack" force-app/ --include="*.cls"

# Find in Visualforce
grep -ri "npsp\|nonprofit success pack" force-app/ --include="*.page"

# Find in Lightning
grep -ri "npsp\|nonprofit success pack" force-app/ --include="*.js" --include="*.html"

# Find in object/field metadata
grep -ri "npsp\|nonprofit success pack" force-app/ --include="*.xml"
```

## Implementation Considerations

1. **Backwards Compatibility**: Existing users expect "NPSP" terminology
2. **Translation Support**: Product name may need translation in labels
3. **Fork-Friendly**: Configuration should be simple for forks to customize
4. **Build Pipeline**: Token replacement must happen before packaging
5. **Testing**: Tests shouldn't depend on specific product name strings

## Acceptance Criteria

- [ ] Product name configurable in single location
- [ ] All UI-visible "NPSP" references use the configured name
- [ ] Documentation for forks on how to rebrand
- [ ] CCI task (if token approach) is idempotent and reversible
- [ ] No hardcoded product names remain in user-facing strings

## Related Work

- Namespace consolidation (separate issue)
- Custom label audit for 2GP compatibility
