from cumulusci.tasks.salesforce import BaseSalesforceApiTask


class ListOrgObjects(BaseSalesforceApiTask):
    """List API names and labels of every object in the org."""

    task_options = {
        "output_path": {
            "description": "Path to the output text file",
            "required": True,
        },
    }

    def _run_task(self):
        output_path = self.options["output_path"]

        # Describe the org to get all sObjects
        self.logger.info("Describing org to retrieve all sObjects...")
        describe_result = self.sf.describe()
        sobjects = describe_result.get("sobjects", [])

        # Sort by API name for stable output
        sobjects = sorted(sobjects, key=lambda s: s.get("name", ""))

        lines = []
        lines.append("List of objects in org")
        lines.append("=======================")
        lines.append("")  # blank line

        for sobj in sobjects:
            api_name = sobj.get("name", "")
            label = sobj.get("label", "")
            custom = sobj.get("custom", False)

            # Example line: Account (Account) [standard]
            type_tag = "custom" if custom else "standard"
            lines.append(f"{api_name} ({label}) [{type_tag}]")

        with open(output_path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))

        self.logger.info(f"Wrote object list to {output_path}")
