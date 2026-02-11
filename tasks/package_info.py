"""Task to display package installation information."""

from cumulusci.core.tasks import BaseTask


class LogPackageInstallInfo(BaseTask):
    """Display package installation command and URL after package version creation."""

    task_docs = """
    Displays the SF CLI command and URL for installing a package version.
    Typically used after create_package_version in a flow.
    """

    task_options = {
        "version_number": {
            "description": "The package version number (e.g., 1.0.0.1)",
            "required": True,
        },
        "package_version_id": {
            "description": "The SubscriberPackageVersion Id (04t...)",
            "required": True,
        },
    }

    def _run_task(self):
        version = self.options.get("version_number")
        package_id = self.options.get("package_version_id")

        self.logger.info("")
        self.logger.info("=" * 60)
        self.logger.info("PACKAGE INSTALLATION INFO")
        self.logger.info("=" * 60)
        self.logger.info("")
        self.logger.info(f"  Package Version: {version}")
        self.logger.info(f"  Package ID: {package_id}")
        self.logger.info("")
        self.logger.info("  Install via SF CLI:")
        self.logger.info(f"    sf package install --package {package_id} --target-org <org-alias> --wait 10")
        self.logger.info("")
        self.logger.info("  Install via URL:")
        self.logger.info(f"    https://login.salesforce.com/packaging/installPackage.apexp?p0={package_id}")
        self.logger.info("")
        self.logger.info("=" * 60)
