#!/bin/bash
# Script to add %%%NAMESPACE%%% tokens to custom field/object references
# that don't already have them

set -e

FORCE_APP="/Users/laurameerkatz/Projects/nppatch/force-app/main/default"

echo "=== Adding namespace tokens to metadata ==="

# Function to add namespace tokens to a file
# Patterns to handle:
# 1. <field>CustomField__c</field> -> <field>%%%NAMESPACE%%%CustomField__c</field>
# 2. Account.CustomField__c -> Account.%%%NAMESPACE%%%CustomField__c
# 3. Contact.CustomField__c -> Contact.%%%NAMESPACE%%%CustomField__c
# 4. Opportunity.CustomField__c -> Opportunity.%%%NAMESPACE%%%CustomField__c
# 5. Campaign.CustomField__c -> Campaign.%%%NAMESPACE%%%CustomField__c
# 6. CustomObject__c references in related lists, report types, etc.

# Standard objects that need namespace tokens on their custom fields
STANDARD_OBJECTS="Account|Contact|Opportunity|Campaign|Lead|Case|Task|Event|User"

echo ""
echo "--- Processing standard object layouts ---"
# Process layouts for standard objects (Account, Contact, Opportunity, Campaign)
for layout in "$FORCE_APP"/layouts/Account-*.layout-meta.xml \
              "$FORCE_APP"/layouts/Contact-*.layout-meta.xml \
              "$FORCE_APP"/layouts/Opportunity-*.layout-meta.xml \
              "$FORCE_APP"/layouts/Campaign-*.layout-meta.xml; do
    if [[ -f "$layout" ]]; then
        # Add namespace token to <field>CustomField__c</field> patterns
        # But skip if already has %%%NAMESPACE%%%
        if grep -q '<field>[A-Za-z_]*__c</field>' "$layout" 2>/dev/null; then
            echo "Processing fields: $(basename "$layout")"
            # Replace <field>SomeField__c</field> with <field>%%%NAMESPACE%%%SomeField__c</field>
            # Only if not already prefixed with %%%NAMESPACE%%%
            sed -i '' -E 's/<field>([A-Za-z_]+__c)<\/field>/<field>%%%NAMESPACE%%%\1<\/field>/g' "$layout"
        fi
    fi
done

echo ""
echo "--- Processing related lists in all layouts ---"
# Process related lists in ALL layouts (custom object references)
for layout in "$FORCE_APP"/layouts/*.layout-meta.xml; do
    if [[ -f "$layout" ]]; then
        # Add namespace token to <relatedList>CustomObject__c.CustomField__c</relatedList>
        if grep -qE '<relatedList>[A-Za-z_]+__c\.[A-Za-z_]+__c</relatedList>' "$layout" 2>/dev/null; then
            echo "Processing related lists: $(basename "$layout")"
            # Replace CustomObject__c.CustomField__c with %%%NAMESPACE%%%CustomObject__c.%%%NAMESPACE%%%CustomField__c
            sed -i '' -E 's/<relatedList>([A-Za-z_]+__c)\.([A-Za-z_]+__c)<\/relatedList>/<relatedList>%%%NAMESPACE%%%\1.%%%NAMESPACE%%%\2<\/relatedList>/g' "$layout"
        fi
        # Also handle standard object lookups like Opportunity.Previous_Grant_Opportunity__c
        if grep -qE '<relatedList>(Account|Contact|Opportunity|Campaign)\.[A-Za-z_]+__c</relatedList>' "$layout" 2>/dev/null; then
            echo "Processing standard object related lists: $(basename "$layout")"
            sed -i '' -E 's/<relatedList>(Account|Contact|Opportunity|Campaign)\.([A-Za-z_]+__c)<\/relatedList>/<relatedList>\1.%%%NAMESPACE%%%\2<\/relatedList>/g' "$layout"
        fi
    fi
done

echo ""
echo "--- Processing reports ---"
# Process reports - add namespace to standard object field references
for report in "$FORCE_APP"/reports/*/*.report-meta.xml; do
    if [[ -f "$report" ]]; then
        modified=false

        # Check if file has patterns that need fixing
        if grep -qE "(Account|Contact|Opportunity|Campaign)\.[A-Za-z_]+__c" "$report" 2>/dev/null; then
            modified=true
        fi

        if [[ "$modified" == "true" ]]; then
            echo "Processing: $(basename "$report")"
            # Add namespace token after standard object prefix for custom fields
            # Account.Field__c -> Account.%%%NAMESPACE%%%Field__c
            sed -i '' -E 's/(Account|Contact|Opportunity|Campaign)\.([A-Za-z_]+__c)/\1.%%%NAMESPACE%%%\2/g' "$report"
        fi
    fi
done

echo ""
echo "--- Processing validation rules ---"
# Process validation rules
for rule in "$FORCE_APP"/objects/*/validationRules/*.validationRule-meta.xml; do
    if [[ -f "$rule" ]]; then
        # Check for custom field references without namespace token
        if grep -qE '\$[A-Za-z_]+\.[A-Za-z_]+__c' "$rule" 2>/dev/null || \
           grep -qE 'ISCHANGED\([A-Za-z_]+__c\)' "$rule" 2>/dev/null; then
            echo "Processing: $(basename "$rule")"
            # Add namespace to field references in formulas like ISCHANGED(Field__c)
            sed -i '' -E 's/ISCHANGED\(([A-Za-z_]+__c)\)/ISCHANGED(%%%NAMESPACE%%%\1)/g' "$rule"
            sed -i '' -E 's/ISNEW\(([A-Za-z_]+__c)\)/ISNEW(%%%NAMESPACE%%%\1)/g' "$rule"
            sed -i '' -E 's/ISBLANK\(([A-Za-z_]+__c)\)/ISBLANK(%%%NAMESPACE%%%\1)/g' "$rule"
            sed -i '' -E 's/PRIORVALUE\(([A-Za-z_]+__c)\)/PRIORVALUE(%%%NAMESPACE%%%\1)/g' "$rule"
            # Handle errorDisplayField
            sed -i '' -E 's/<errorDisplayField>([A-Za-z_]+__c)<\/errorDisplayField>/<errorDisplayField>%%%NAMESPACE%%%\1<\/errorDisplayField>/g' "$rule"
        fi
    fi
done

echo ""
echo "--- Processing flexipages ---"
# Process flexipages
for page in "$FORCE_APP"/flexipages/*.flexipage-meta.xml; do
    if [[ -f "$page" ]]; then
        if grep -qE 'Record\.[A-Za-z_]+__c' "$page" 2>/dev/null; then
            echo "Processing: $(basename "$page")"
            # Handle {!Record.Field__c} patterns
            sed -i '' -E 's/Record\.([A-Za-z_]+__c)/Record.%%%NAMESPACE%%%\1/g' "$page"
        fi
    fi
done

echo ""
echo "--- Processing formula fields on standard objects ---"
# Process formula fields on standard objects (Account, Contact, Opportunity, Campaign)
# Use Python for more precise formula parsing
python3 << 'PYTHON_SCRIPT'
import os
import re
import glob

force_app = "/Users/laurameerkatz/Projects/nppatch/force-app/main/default"

for obj in ["Account", "Contact", "Opportunity", "Campaign"]:
    pattern = f"{force_app}/objects/{obj}/fields/*.field-meta.xml"
    for filepath in glob.glob(pattern):
        with open(filepath, 'r') as f:
            content = f.read()

        if '<formula>' not in content:
            continue

        # Extract formula content
        formula_match = re.search(r'<formula>(.*?)</formula>', content, re.DOTALL)
        if not formula_match:
            continue

        formula = formula_match.group(1)
        original_formula = formula

        # Add namespace tokens to custom field references in formula
        # Pattern 1: $Setup.CustomSettings__c.Field__c
        formula = re.sub(
            r'\$Setup\.([A-Za-z_]+__c)\.([A-Za-z_]+__c)',
            r'$Setup.%%%NAMESPACE%%%\1.%%%NAMESPACE%%%\2',
            formula
        )

        # Pattern 2: Object.Field__c (standard object lookups)
        formula = re.sub(
            r'(Account|Contact|Opportunity|Campaign)\.([A-Za-z_]+__c)',
            r'\1.%%%NAMESPACE%%%\2',
            formula
        )

        # Pattern 3: Standalone field references - be more aggressive
        # Match word boundary + field name ending in __c, not preceded by . or %
        # This handles: (Field__c, ,Field__c, Field__c< Field__c> Field__c= etc
        formula = re.sub(
            r'(?<![.%A-Za-z_])([A-Za-z_]+__c)(?![A-Za-z_])',
            r'%%%NAMESPACE%%%\1',
            formula
        )

        if formula != original_formula:
            print(f"Processing formula: {os.path.basename(filepath)}")
            new_content = content.replace(f'<formula>{original_formula}</formula>',
                                          f'<formula>{formula}</formula>')
            with open(filepath, 'w') as f:
                f.write(new_content)
PYTHON_SCRIPT

echo ""
echo "--- Cleaning up double tokens ---"
# Clean up any accidental double namespace tokens
for file in "$FORCE_APP"/layouts/*.layout-meta.xml \
            "$FORCE_APP"/reports/*/*.report-meta.xml \
            "$FORCE_APP"/objects/*/validationRules/*.validationRule-meta.xml \
            "$FORCE_APP"/flexipages/*.flexipage-meta.xml; do
    if [[ -f "$file" ]]; then
        if grep -q '%%%NAMESPACE%%%%%%NAMESPACE%%%' "$file" 2>/dev/null; then
            echo "Fixing double tokens in: $(basename "$file")"
            sed -i '' 's/%%%NAMESPACE%%%%%%NAMESPACE%%%/%%%NAMESPACE%%%/g' "$file"
        fi
    fi
done

echo ""
echo "=== Done! ==="
echo ""
echo "Run 'cci flow run dev_org --org dev' to test the deployment."
