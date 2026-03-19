import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "lightning/uiRecordApi";
import getErrors from "@salesforce/apex/ErrorLogController.getErrors";
import clearErrors from "@salesforce/apex/ErrorLogController.clearErrors";

const COLUMNS = [
    {
        label: "Date/Time",
        fieldName: "Datetime__c",
        type: "date",
        typeAttributes: { year: "numeric", month: "short", day: "2-digit", hour: "2-digit", minute: "2-digit" },
        sortable: true,
        initialWidth: 180,
    },
    { label: "Context", fieldName: "Context_Type__c", type: "text", sortable: true, initialWidth: 180 },
    { label: "Object Type", fieldName: "Object_Type__c", type: "text", sortable: true, initialWidth: 150 },
    { label: "Error Type", fieldName: "Error_Type__c", type: "text", sortable: true, initialWidth: 150 },
    { label: "Message", fieldName: "Full_Message__c", type: "text", wrapText: true },
];

export default class StgPanelErrorLog extends LightningElement {
    _errors = [];
    _wiredResult;
    _isClearing = false;
    _sortedBy = "Datetime__c";
    _sortedDirection = "desc";
    _lastRefreshed = null;

    columns = COLUMNS;

    @wire(getErrors)
    wiredErrors(result) {
        this._wiredResult = result;
        if (result.data) {
            this._errors = [...result.data];
            this._sortData();
            this._lastRefreshed = new Date().toLocaleString();
        }
    }

    get isLoading() {
        return !this._wiredResult;
    }

    get hasRecords() {
        return this._errors && this._errors.length > 0;
    }

    get errorCount() {
        return this._errors ? this._errors.length : 0;
    }

    async handleRefresh() {
        await refreshApex(this._wiredResult);
        this.dispatchEvent(
            new ShowToastEvent({
                title: "Refreshed",
                message: `${this.errorCount} error${this.errorCount === 1 ? "" : "s"} found.`,
                variant: "info",
            })
        );
    }

    async handleClear() {
        this._isClearing = true;
        try {
            await clearErrors();
            await refreshApex(this._wiredResult);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Error log has been cleared.",
                    variant: "success",
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: error?.body?.message || "Failed to clear errors.",
                    variant: "error",
                })
            );
        } finally {
            this._isClearing = false;
        }
    }

    handleSort(event) {
        this._sortedBy = event.detail.fieldName;
        this._sortedDirection = event.detail.sortDirection;
        this._sortData();
    }

    _sortData() {
        const data = [...this._errors];
        const field = this._sortedBy;
        const direction = this._sortedDirection === "asc" ? 1 : -1;
        data.sort((a, b) => {
            const aVal = a[field] || "";
            const bVal = b[field] || "";
            return direction * (aVal > bVal ? 1 : aVal < bVal ? -1 : 0);
        });
        this._errors = data;
    }
}
