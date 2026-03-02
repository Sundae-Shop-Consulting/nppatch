import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getListSettings from "@salesforce/apex/NppatchSettingsController.getListSettings";
import createListSetting from "@salesforce/apex/NppatchSettingsController.createListSetting";
import deleteListSetting from "@salesforce/apex/NppatchSettingsController.deleteListSetting";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

const DATA_COLUMNS = [
    { label: "Name", fieldName: "Name", type: "text" },
    { label: "Male", fieldName: "Male__c", type: "text" },
    { label: "Female", fieldName: "Female__c", type: "text" },
    { label: "Neutral", fieldName: "Neutral__c", type: "text" },
];

const ACTION_COLUMN = {
    type: "action",
    typeAttributes: {
        rowActions: [{ label: "Delete", name: "delete" }],
    },
};

export default class StgPanelRelReciprocal extends LightningElement {
    _settings;
    _wiredResult;
    _canEdit = false;
    _isCreating = false;
    _isSaving = false;
    _hasError = false;
    _errorMessage = "";
    @track _newRecord = { Name: "", Male__c: "", Female__c: "", Neutral__c: "" };

    labels = {
        sectionLabel: "Relationships",
        pageLabel: "Reciprocal Relationships",
        description:
            "Reciprocal Relationships automatically create a matching relationship in the opposite direction. " +
            "For example, when you mark someone as a \u2018Father,\u2019 a \u2018Son\u2019 or \u2018Daughter\u2019 relationship is created on the other Contact. " +
            "These rules define how each relationship type maps to its reciprocal based on the Contact\u2019s gender.",
    };

    @wire(isAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this._canEdit = data;
        }
    }

    @wire(getListSettings, { settingsObjectName: "Relationship_Lookup__c" })
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
        this._newRecord = { Name: "", Male__c: "", Female__c: "", Neutral__c: "" };
    }

    handleCancelNew() {
        this._isCreating = false;
    }

    handleNewNameChange(event) {
        this._newRecord = { ...this._newRecord, Name: event.detail.value };
    }

    handleNewMaleChange(event) {
        this._newRecord = { ...this._newRecord, Male__c: event.detail.value };
    }

    handleNewFemaleChange(event) {
        this._newRecord = { ...this._newRecord, Female__c: event.detail.value };
    }

    handleNewNeutralChange(event) {
        this._newRecord = { ...this._newRecord, Neutral__c: event.detail.value };
    }

    async handleSaveNew() {
        if (!this._newRecord.Name) {
            this.dispatchEvent(new ShowToastEvent({ title: "Error", message: "Name is required.", variant: "error" }));
            return;
        }
        this._isSaving = true;
        try {
            await createListSetting({
                settingsObjectName: "Relationship_Lookup__c",
                fieldValues: this._newRecord,
            });
            await refreshApex(this._wiredResult);
            this._isCreating = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Reciprocal relationship created.",
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
                await deleteListSetting({
                    settingsObjectName: "Relationship_Lookup__c",
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
