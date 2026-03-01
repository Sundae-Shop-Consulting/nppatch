import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import runBatch from "@salesforce/apex/NppatchSettingsController.runBatch";

export default class StgPanelCreatePayments extends LightningElement {
    _isRunning = false;
    _hasError = false;
    _errorMessage = "";
    @api isAdmin = false;

    labels = {
        sectionLabel: "Bulk Data Processes",
        pageLabel: "Create Missing Payments",
        description:
            "Creates Payment records for existing Opportunities that should have them but don't. This is useful after enabling Automatic Payments to backfill Payments for historical Opportunities.",
        runBatch: "Create Missing Payments",
        runningMessage:
            "Batch job submitted. Check the Apex Jobs page for progress.",
    };

    get isLoading() {
        return false;
    }

    async handleRunBatch() {
        this._isRunning = true;
        this._hasError = false;
        try {
            await runBatch({ batchName: "createPayments" });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Batch job has been submitted.",
                    variant: "success",
                })
            );
        } catch (error) {
            this._hasError = true;
            this._errorMessage =
                error?.body?.message || "An error occurred.";
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: this._errorMessage,
                    variant: "error",
                })
            );
        } finally {
            this._isRunning = false;
        }
    }
}
