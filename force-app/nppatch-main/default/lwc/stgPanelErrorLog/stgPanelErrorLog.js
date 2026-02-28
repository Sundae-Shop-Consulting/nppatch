import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// TODO: Add getErrorLog to NppatchSettingsController
// import getErrorLog from "@salesforce/apex/NppatchSettingsController.getErrorLog";

const COLUMNS = [
    { label: "Date/Time", fieldName: "CreatedDate", type: "date",
        typeAttributes: { year: "numeric", month: "short", day: "2-digit", hour: "2-digit", minute: "2-digit" },
        sortable: true, initialWidth: 180 },
    { label: "Context", fieldName: "Context_Type__c", type: "text", sortable: true, initialWidth: 200 },
    { label: "Object Type", fieldName: "Object_Type__c", type: "text", sortable: true, initialWidth: 150 },
    { label: "Error Type", fieldName: "Error_Type__c", type: "text", sortable: true, initialWidth: 150 },
    { label: "Message", fieldName: "Full_Message__c", type: "text", wrapText: true },
];

export default class StgPanelErrorLog extends LightningElement {
    _errors = [];
    _hasError = false;
    _errorMessage = "";
    _isLoaded = false;
    _sortedBy = "CreatedDate";
    _sortedDirection = "desc";

    columns = COLUMNS;

    connectedCallback() {
        this._isLoaded = true;
        // TODO: Load errors when Apex method is ready
        // this.loadErrors();
    }

    get isLoading() {
        return !this._isLoaded;
    }

    get hasRecords() {
        return this._errors && this._errors.length > 0;
    }

    handleRefresh() {
        // TODO: Refresh errors
        this.dispatchEvent(new ShowToastEvent({
            title: "Info",
            message: "Error Log API is being migrated. For now, view errors from the classic NPPatch Settings page.",
            variant: "info",
        }));
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
