import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import runBatch from "@salesforce/apex/NppatchSettingsController.runBatch";

export default class StgPanelAlloBatch extends LightningElement {
    _isRunning = false;
    _hasError = false;
    _errorMessage = "";
    @api isAdmin = false;

    labels = {
        sectionLabel: "Bulk Data Processes",
        pageLabel: "Allocation Rollup Batch",
        description:
            "Recalculates rollup totals for General Accounting Units (GAUs). Run this after creating or modifying Allocations to ensure GAU summary fields are current.",
        runBatch: "Run Allocation Rollup",
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
            await runBatch({ batchName: "alloBatch" });
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
