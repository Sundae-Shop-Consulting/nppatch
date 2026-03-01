import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import runBatch from "@salesforce/apex/NppatchSettingsController.runBatch";

export default class StgPanelPrimaryContactRoleMerge extends LightningElement {
    _isRunning = false;
    _hasError = false;
    _errorMessage = "";
    @api isAdmin = false;

    labels = {
        sectionLabel: "Bulk Data Processes",
        pageLabel: "Primary Contact Role Merge",
        description:
            "Identifies Opportunities with duplicate Primary Contact Roles and removes the extras, keeping only one Primary OCR per Opportunity. This cleans up data that may have been created by earlier versions or data imports.",
        runBatch: "Remove Duplicate Primary OCRs",
        runningMessage: "Batch job is running...",
    };

    get isLoading() {
        return false;
    }

    async handleRunBatch() {
        this._isRunning = true;
        this._hasError = false;
        try {
            await runBatch({ batchName: "primaryContactRoleMerge" });
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
