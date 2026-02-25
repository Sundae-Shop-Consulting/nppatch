# tasks/object_reference.py

import yaml
from cumulusci.tasks.salesforce import BaseSalesforceApiTask


class GenerateObjectReference(BaseSalesforceApiTask):
    """Generate a structured YAML data dictionary for selected objects."""

    task_options = {
        "objects": {
            "description": "Comma-separated list of object API names (e.g. 'Account,Contact')",
            "required": True,
        },
        "output_path": {
            "description": "Path to the output YAML file",
            "required": True,
        },
    }

    # Standard Salesforce system fields (explicit exclusions)
    SYSTEM_FIELDS = {
        "Id",
        "OwnerId",
        "IsDeleted",
        "CreatedById",
        "CreatedDate",
        "LastModifiedById",
        "LastModifiedDate",
        "SystemModstamp",
        "LastReferencedDate",
        "LastViewedDate",
        "MasterRecordId",
        "ConnectionReceivedId",
        "ConnectionSentId",
    }

    def _is_excluded_by_name(self, field_name: str) -> bool:
        """Skip state/country/timezone-style fields for now."""
        lower = field_name.lower()
        if lower.endswith("state") or lower.endswith("country") or lower.endswith("timezone"):
            return True
        # Common SF timezone field
        if lower in ("timezonesidkey",):
            return True
        return False

    def _run_task(self):
        object_names = [
            o.strip()
            for o in self.options["objects"].split(",")
            if o.strip()
        ]
        output_path = self.options["output_path"]

        result = {
            "objects": [],
            "errors": [],
        }

        for obj in object_names:
            try:
                desc = getattr(self.sf, obj).describe()
            except Exception as e:
                result["errors"].append(
                    {"object": obj, "message": f"Could not describe object: {e}"}
                )
                continue

            obj_entry = {"name": obj, "fields": []}

            for field in desc["fields"]:
                fname = field["name"]
                ftype = field["type"]

                # Skip explicit system fields
                if fname in self.SYSTEM_FIELDS:
                    continue

                # Skip state/country/timezone style fields entirely (per current plan)
                if self._is_excluded_by_name(fname):
                    continue

                createable = field.get("createable", False)
                updateable = field.get("updateable", False)
                calculated = field.get("calculated", False)

                # Skip fully system-managed fields (not createable/updateable and not formula)
                if not createable and not updateable and not calculated:
                    continue

                auto_number = field.get("autoNumber", False)

                # Normalize access
                if updateable:
                    access = "read_write"
                elif createable:
                    access = "create_only"
                else:
                    access = "read_only"

                # Requiredness:
                # Rough rule: not nillable and no default => required on create.
                nillable = field.get("nillable", True)
                defaulted_on_create = field.get("defaultedOnCreate", False)
                is_required = (not nillable) and (not defaulted_on_create)

                field_entry = {
                    "name": fname,
                    "type": ftype,
                    "access": access,
                    "is_formula": bool(calculated),
                    "is_auto_number": bool(auto_number),
                    "is_required": bool(is_required),
                }

                # ----- Lookups / references -----
                if ftype == "reference":
                    ref_to = field.get("referenceTo") or []
                    relationship_name = field.get("relationshipName")
                    ref_info = {
                        # Typically a list of one, but keep full list just in case.
                        "reference_to": ref_to,
                    }
                    if relationship_name:
                        ref_info["relationship_name"] = relationship_name
                    field_entry["reference"] = ref_info

                # ----- Picklists -----
                if ftype == "picklist":
                    values = [v["value"] for v in field.get("picklistValues", [])]

                    if len(values) <= 5:
                        picklist_info = {
                            "initial_values": values,
                            "total_values": len(values),
                        }
                    else:
                        picklist_info = {
                            "initial_values": values[:5],
                            "total_values": len(values),
                        }

                    field_entry["picklist"] = picklist_info

                obj_entry["fields"].append(field_entry)

            result["objects"].append(obj_entry)

        # ---------- Write YAML ----------
        with open(output_path, "w", encoding="utf-8") as f:
            yaml.safe_dump(
                result,
                f,
                sort_keys=False,
                allow_unicode=True,
                default_flow_style=False,
            )

        self.logger.info(f"Object reference (YAML) written to {output_path}")
