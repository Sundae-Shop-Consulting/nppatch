import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import runBatch from "@salesforce/apex/BulkProcessController.runBatch";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

export default class StgPanelUpdatePrimaryContact extends LightningElement {
    _isRunning = false;
    _hasError = false;
    _errorMessage = "";
    _canEdit = false;

    labels = {
        sectionLabel: "Bulk Data Processes",
        pageLabel: "Update Primary Contact",
        description:
            "Updates the Primary Contact lookup field on all Opportunities based on their Contact Roles. Run this to fix Opportunities where the Primary Contact is missing or incorrect.",
        runBatch: "Update Primary Contacts",
        runningMessage: "Batch job is running...",
    };

    @wire(isAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this._canEdit = data;
        }
    }

    get isLoading() {
        return false;
    }

    async handleRunBatch() {
        this._isRunning = true;
        this._hasError = false;
        try {
            await runBatch({ batchName: "updatePrimaryContact" });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Batch job has been submitted.",
                    variant: "success",
                })
            );
        } catch (error) {
            this._hasError = true;
            this._errorMessage = error?.body?.message || "An error occurred.";
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
