import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import runBatch from "@salesforce/apex/BulkProcessController.runBatch";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

export default class StgPanelLvlAssignBatch extends LightningElement {
    _isRunning = false;
    _hasError = false;
    _errorMessage = "";
    _canEdit = false;

    labels = {
        sectionLabel: "Bulk Data Processes",
        pageLabel: "Level Assignment Batch",
        description:
            "Evaluates all Level definitions and assigns the appropriate Level to each Account, Contact, or other target object. Run this after creating or modifying Level rules to apply them across existing records.",
        runBatch: "Run Level Assignment",
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
            await runBatch({ batchName: "lvlAssignBatch" });
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
