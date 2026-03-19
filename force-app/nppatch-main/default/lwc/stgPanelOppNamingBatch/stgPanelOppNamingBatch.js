import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import runBatch from "@salesforce/apex/BulkProcessController.runBatch";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

export default class StgPanelOppNamingBatch extends LightningElement {
    _isRunning = false;
    _hasError = false;
    _errorMessage = "";
    _canEdit = false;

    labels = {
        sectionLabel: "Bulk Data Processes",
        pageLabel: "Opportunity Naming Refresh",
        description:
            "Regenerates the Name field on all Opportunities based on the current Opportunity Naming settings. Run this after changing naming format rules to apply the updated format to existing Opportunities.",
        runBatch: "Refresh Opportunity Names",
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
            await runBatch({ batchName: "oppNamingBatch" });
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
