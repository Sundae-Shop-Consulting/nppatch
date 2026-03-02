import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getListSettings from "@salesforce/apex/NppatchSettingsController.getListSettings";
import createListSetting from "@salesforce/apex/NppatchSettingsController.createListSetting";
import deleteListSetting from "@salesforce/apex/NppatchSettingsController.deleteListSetting";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

const SETTINGS_OBJECT = "Payment_Field_Mapping_Settings__c";

const DATA_COLUMNS = [
    { label: "Opportunity Field", fieldName: "Opportunity_Field__c", type: "text" },
    { label: "Payment Field", fieldName: "Payment_Field__c", type: "text" },
];

const ACTION_COLUMN = {
    type: "action",
    typeAttributes: {
        rowActions: [{ label: "Delete", name: "delete" }],
    },
};

export default class StgPanelPaymentMapping extends LightningElement {
    _settings;
    _wiredResult;
    _canEdit = false;
    _isCreating = false;
    _isSaving = false;
    _hasError = false;
    _errorMessage = "";
    @track _newRecord = { Opportunity_Field__c: "", Payment_Field__c: "" };

    labels = {
        sectionLabel: "Donations",
        pageLabel: "Payment Mappings",
        description:
            "Payment Field Mappings automatically copy values from Opportunity fields to Payment fields when Payments are created. " +
            "For example, you can map the Opportunity\u2019s custom \u2018Fund\u2019 field to a \u2018Fund\u2019 field on the Payment record.",
    };

    @wire(isAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this._canEdit = data;
        }
    }

    @wire(getListSettings, { settingsObjectName: SETTINGS_OBJECT })
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
        this._newRecord = { Opportunity_Field__c: "", Payment_Field__c: "" };
    }

    handleCancelNew() {
        this._isCreating = false;
    }

    handleNewOpportunityFieldChange(event) {
        this._newRecord = { ...this._newRecord, Opportunity_Field__c: event.detail.value };
    }

    handleNewPaymentFieldChange(event) {
        this._newRecord = { ...this._newRecord, Payment_Field__c: event.detail.value };
    }

    async handleSaveNew() {
        if (!this._newRecord.Opportunity_Field__c || !this._newRecord.Payment_Field__c) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: "Both Opportunity Field and Payment Field are required.",
                    variant: "error",
                })
            );
            return;
        }
        this._isSaving = true;
        try {
            await createListSetting({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: this._newRecord,
            });
            await refreshApex(this._wiredResult);
            this._isCreating = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Payment field mapping created.",
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
                    settingsObjectName: SETTINGS_OBJECT,
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
