#!/usr/bin/env python3
"""
Generate a permission set that grants access to all package objects and fields.
This is needed for 2GP package tests to pass FLS checks.
"""

import os
import xml.etree.ElementTree as ET
from pathlib import Path

FORCE_APP = Path("/Users/laurameerkatz/Projects/nppatch/force-app")
OBJECTS_DIR = FORCE_APP / "main/default/objects"
OUTPUT_FILE = FORCE_APP / "main/default/permissionsets/NPPatch_Admin.permissionset-meta.xml"

# Custom settings don't need object permissions (they're accessed via Apex)
CUSTOM_SETTINGS = {
    "Addr_Verification_Settings__c",
    "Address_Verification_Settings__c",
    "Affiliations_Settings__c",
    "Allocations_Settings__c",
    "Batch_Data_Entry_Settings__c",
    "Contacts_And_Orgs_Settings__c",
    "Custom_Column_Header__c",
    "Custom_Field_Mapping__c",
    "Custom_Installment_Settings__c",
    "Customizable_Rollup_Settings__c",
    "Data_Import_Settings__c",
    "Error_Settings__c",
    "Gift_Entry_Settings__c",
    "Household_Naming_Settings__c",
    "Households_Settings__c",
    "Levels_Settings__c",
    "Opportunity_Naming_Settings__c",
    "Package_Settings__c",
    "Payment_Field_Mapping_Settings__c",
    "Payment_Services_Configuration__c",
    "Recurring_Donations_Settings__c",
    "Relationship_Auto_Create__c",
    "Relationship_Lookup__c",
    "Relationship_Settings__c",
    "Relationship_Sync_Excluded_Fields__c",
    "User_Rollup_Field_Settings__c",
}

# Custom metadata types don't need object permissions
CUSTOM_METADATA_TYPES = {
    "Custom_Notification__mdt",
    "Data_Import_Field_Mapping_Set__mdt",
    "Data_Import_Field_Mapping__mdt",
    "Data_Import_Object_Mapping_Set__mdt",
    "Data_Import_Object_Mapping__mdt",
    "Filter_Group__mdt",
    "Filter_Rule__mdt",
    "GetStartedChecklistItem__mdt",
    "GetStartedChecklistSection__mdt",
    "Opportunity_Stage_To_State_Mapping__mdt",
    "RecurringDonationStatusMapping__mdt",
    "Rollup__mdt",
}

# Standard objects with custom fields
STANDARD_OBJECTS = {"Account", "Activity", "Campaign", "Contact", "Lead", "Opportunity"}

# Standard objects that need CRUD permissions (custom objects have relationships to these)
STANDARD_OBJECTS_FOR_CRUD = {"Account", "Contact", "Opportunity", "Campaign", "Lead", "Case", "Task"}

def get_all_objects():
    """Get all object directories."""
    objects = []
    if OBJECTS_DIR.exists():
        for obj_dir in OBJECTS_DIR.iterdir():
            if obj_dir.is_dir():
                objects.append(obj_dir.name)
    return sorted(objects)

def get_fields_for_object(object_name):
    """Get all custom field names for an object."""
    fields = []
    fields_dir = OBJECTS_DIR / object_name / "fields"
    if fields_dir.exists():
        for field_file in fields_dir.glob("*.field-meta.xml"):
            field_name = field_file.stem.replace(".field-meta", "")
            # Only include custom fields (ending in __c)
            if field_name.endswith("__c"):
                fields.append(field_name)
    return sorted(fields)

def get_field_info(object_name, field_name):
    """Get field info: returns (skip_entirely, is_formula).

    skip_entirely: True for required fields and master-detail (can't have any permission entry)
    is_formula: True for formula fields (can have permission but editable=false)
    """
    field_file = OBJECTS_DIR / object_name / "fields" / f"{field_name}.field-meta.xml"
    if field_file.exists():
        try:
            tree = ET.parse(field_file)
            root = tree.getroot()
            ns = {'sf': 'http://soap.sforce.com/2006/04/metadata'}

            # Get field type
            field_type = root.find('.//sf:type', ns)
            field_type_text = field_type.text if field_type is not None else ""

            # Master-Detail fields must be skipped entirely (can't set any permission)
            if field_type_text == "MasterDetail":
                return (True, False)

            # ANY required field must be skipped entirely (can't set any permission)
            required = root.find('.//sf:required', ns)
            if required is not None and required.text == "true":
                return (True, False)

            # Formula fields can have permission but are read-only
            formula = root.find('.//sf:formula', ns)
            if formula is not None and formula.text:
                return (False, True)

        except:
            pass
    return (False, False)

def add_namespace_token(name):
    """Add %%%NAMESPACE%%% token to custom field/object names."""
    if name.endswith("__c"):
        return "%%%NAMESPACE%%%" + name
    return name

def generate_permission_set():
    """Generate the permission set XML."""

    # XML namespace
    ns = "http://soap.sforce.com/2006/04/metadata"
    ET.register_namespace('', ns)

    root = ET.Element("PermissionSet", xmlns=ns)

    # Basic info
    ET.SubElement(root, "description").text = "Full access to all nppatch package objects and fields. Required for admin users and package tests."
    ET.SubElement(root, "hasActivationRequired").text = "false"
    ET.SubElement(root, "label").text = "nppatch Admin"
    ET.SubElement(root, "license").text = "Salesforce"

    all_objects = get_all_objects()

    # Add field permissions for all objects (including standard objects with custom fields)
    skipped_fields = []
    for object_name in all_objects:
        fields = get_fields_for_object(object_name)
        # Add namespace token to custom objects
        ns_object_name = add_namespace_token(object_name)
        for field_name in fields:
            skip_entirely, is_formula = get_field_info(object_name, field_name)
            # Skip required lookups and master-detail fields entirely
            if skip_entirely:
                skipped_fields.append(f"{object_name}.{field_name}")
                continue
            field_perm = ET.SubElement(root, "fieldPermissions")
            ET.SubElement(field_perm, "editable").text = "false" if is_formula else "true"
            # Add namespace token to custom field names
            ns_field_name = add_namespace_token(field_name)
            ET.SubElement(field_perm, "field").text = f"{ns_object_name}.{ns_field_name}"
            ET.SubElement(field_perm, "readable").text = "true"

    # Note: Standard object permissions (Account, Contact, etc.) are intentionally
    # excluded. In 2GP packages, standard object permissions get stripped during
    # packaging, which causes custom object permissions that depend on them to fail
    # at install time. Standard object access must come from the user's profile.

    # Add object permissions for custom objects (not settings or CMT)
    for object_name in all_objects:
        if object_name.endswith("__c") and object_name not in CUSTOM_SETTINGS:
            obj_perm = ET.SubElement(root, "objectPermissions")
            ET.SubElement(obj_perm, "allowCreate").text = "true"
            ET.SubElement(obj_perm, "allowDelete").text = "true"
            ET.SubElement(obj_perm, "allowEdit").text = "true"
            ET.SubElement(obj_perm, "allowRead").text = "true"
            ET.SubElement(obj_perm, "modifyAllRecords").text = "true"
            # Add namespace token to custom object names
            ET.SubElement(obj_perm, "object").text = add_namespace_token(object_name)
            ET.SubElement(obj_perm, "viewAllRecords").text = "true"

    # Write the file
    tree = ET.ElementTree(root)
    ET.indent(tree, space="    ")

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    tree.write(OUTPUT_FILE, encoding="UTF-8", xml_declaration=True)

    # Fix the XML declaration (ElementTree writes it wrong)
    with open(OUTPUT_FILE, 'r') as f:
        content = f.read()
    content = content.replace("<?xml version='1.0' encoding='UTF-8'?>", '<?xml version="1.0" encoding="UTF-8"?>')
    with open(OUTPUT_FILE, 'w') as f:
        f.write(content)

    print(f"Generated permission set: {OUTPUT_FILE}")
    print(f"Objects with permissions: {len([o for o in all_objects if o.endswith('__c') and o not in CUSTOM_SETTINGS])}")
    print(f"Skipped fields (required lookups/master-detail): {len(skipped_fields)}")
    for f in skipped_fields:
        print(f"  - {f}")
    print(f"Total field permissions: {sum(len(get_fields_for_object(o)) for o in all_objects) - len(skipped_fields)}")

if __name__ == "__main__":
    generate_permission_set()
