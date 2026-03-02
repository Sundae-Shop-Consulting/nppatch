import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getTriggerHandlers from "@salesforce/apex/NppatchSettingsController.getTriggerHandlers";
import createTriggerHandler from "@salesforce/apex/NppatchSettingsController.createTriggerHandler";
import deleteTriggerHandler from "@salesforce/apex/NppatchSettingsController.deleteTriggerHandler";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

const DATA_COLUMNS = [
    { label: "Object", fieldName: "Object__c", type: "text" },
    { label: "Class", fieldName: "Class__c", type: "text" },
    { label: "Load Order", fieldName: "Load_Order__c", type: "number" },
    { label: "Trigger Action", fieldName: "Trigger_Action__c", type: "text" },
    { label: "Active", fieldName: "Active__c", type: "boolean" },
    { label: "Async", fieldName: "Asynchronous__c", type: "boolean" },
    { label: "User Managed", fieldName: "User_Managed__c", type: "boolean" },
];

const ACTION_COLUMN = {
    type: "action",
    typeAttributes: {
        rowActions: [{ label: "Delete", name: "delete" }],
    },
};

export default class StgPanelTDTM extends LightningElement {
    _settings;
    _wiredResult;
    _canEdit = false;
    _isCreating = false;
    _isSaving = false;
    _hasError = false;
    _errorMessage = "";
    @track _newRecord = {
        Object__c: "",
        Class__c: "",
        Load_Order__c: null,
        Trigger_Action__c: "",
        Active__c: true,
        Asynchronous__c: false,
    };

    labels = {
        sectionLabel: "System Tools",
        pageLabel: "Trigger Configuration",
        description:
            "Trigger Configuration (TDTM) controls which Apex trigger handlers execute and in what order. " +
            "Each handler is tied to a specific SObject and set of trigger events. The Active flag enables or disables " +
            "individual handlers. Use caution when modifying these settings \u2014 disabling core handlers may break NPPatch functionality.",
    };

    @wire(isAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this._canEdit = data;
        }
    }

    @wire(getTriggerHandlers)
    wiredSettings(result) {
        this._wiredResult = result;
        if (result.data) {
            this._settings = result.data;
            this._hasError = false;
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get hasRecords() {
        return this._settings && this._settings.length > 0;
    }

    get canEdit() {
        return this._canEdit;
    }

    get columns() {
        if (this._canEdit) {
            return [...DATA_COLUMNS, ACTION_COLUMN];
        }
        return DATA_COLUMNS;
    }

    handleNew() {
        this._isCreating = true;
        this._newRecord = {
            Object__c: "",
            Class__c: "",
            Load_Order__c: null,
            Trigger_Action__c: "",
            Active__c: true,
            Asynchronous__c: false,
        };
    }

    handleCancelNew() {
        this._isCreating = false;
    }

    handleNewObjectChange(event) {
        this._newRecord = { ...this._newRecord, Object__c: event.detail.value };
    }

    handleNewClassChange(event) {
        this._newRecord = { ...this._newRecord, Class__c: event.detail.value };
    }

    handleNewLoadOrderChange(event) {
        this._newRecord = { ...this._newRecord, Load_Order__c: event.detail.value };
    }

    handleNewTriggerActionChange(event) {
        this._newRecord = { ...this._newRecord, Trigger_Action__c: event.detail.value };
    }

    handleNewActiveChange(event) {
        this._newRecord = { ...this._newRecord, Active__c: event.detail.checked };
    }

    handleNewAsynchronousChange(event) {
        this._newRecord = { ...this._newRecord, Asynchronous__c: event.detail.checked };
    }

    async handleSaveNew() {
        if (!this._newRecord.Object__c || !this._newRecord.Class__c || this._newRecord.Load_Order__c === null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: "Object, Class, and Load Order are required.",
                    variant: "error",
                })
            );
            return;
        }
        this._isSaving = true;
        try {
            await createTriggerHandler({
                fieldValues: this._newRecord,
            });
            await refreshApex(this._wiredResult);
            this._isCreating = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Trigger handler created.",
                    variant: "success",
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: this._extractError(error),
                    variant: "error",
                })
            );
        } finally {
            this._isSaving = false;
        }
    }

    async handleRowAction(event) {
        if (event.detail.action.name === "delete") {
            try {
                await deleteTriggerHandler({
                    recordId: event.detail.row.Id,
                });
                await refreshApex(this._wiredResult);
                this.dispatchEvent(
                    new ShowToastEvent({ title: "Success", message: "Record deleted.", variant: "success" })
                );
            } catch (error) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: this._extractError(error),
                        variant: "error",
                    })
                );
            }
        }
    }

    _extractError(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return "An unexpected error occurred.";
    }
}
