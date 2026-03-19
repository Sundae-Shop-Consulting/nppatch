import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getListSettings from "@salesforce/apex/NppatchSettingsController.getListSettings";
import createListSetting from "@salesforce/apex/NppatchSettingsController.createListSetting";
import updateListSetting from "@salesforce/apex/NppatchSettingsController.updateListSetting";
import deleteListSetting from "@salesforce/apex/NppatchSettingsController.deleteListSetting";
import getMultiObjectFieldDescribes from "@salesforce/apex/NppatchSettingsController.getMultiObjectFieldDescribes";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

const SETTINGS_OBJECT = "Payment_Field_Mapping_Settings__c";
const FIELD_OBJECTS = ["Opportunity", "OppPayment__c"];

const DATA_COLUMNS = [
    { label: "Opportunity Field", fieldName: "oppFieldDisplay", type: "text" },
    { label: "Payment Field", fieldName: "pmtFieldDisplay", type: "text" },
];

const ACTION_COLUMN = {
    type: "action",
    typeAttributes: {
        rowActions: [
            { label: "Edit", name: "edit" },
            { label: "Delete", name: "delete" },
        ],
    },
};

export default class StgPanelPaymentMapping extends LightningElement {
    _settings;
    _wiredResult;
    _canEdit = false;
    _isCreating = false;
    _isEditing = false;
    _isSaving = false;
    _hasError = false;
    _errorMessage = "";
    @track _newRecord = { Opportunity_Field__c: "", Payment_Field__c: "" };
    @track _editRecord = { Id: "", Opportunity_Field__c: "", Payment_Field__c: "" };

    @track _oppFields = [];
    @track _pmtFields = [];
    _oppLabelMap = {};
    _pmtLabelMap = {};
    _fieldLoadError = "";

    labels = {
        sectionLabel: "Donations",
        pageLabel: "Payment Mappings",
        description:
            "Payment Field Mappings automatically copy values from Opportunity fields to Payment fields when Payments are created. " +
            "For example, you can map the Opportunity\u2019s custom \u2018Fund\u2019 field to a \u2018Fund\u2019 field on the Payment record.",
    };

    @wire(getMultiObjectFieldDescribes, { sObjectApiNames: FIELD_OBJECTS })
    wiredFieldDescribes({ data, error }) {
        if (data) {
            this._oppLabelMap = {};
            this._pmtLabelMap = {};
            const oppData = data.Opportunity || [];
            const pmtData = data.OppPayment__c || [];
            this._oppFields = oppData
                .map((f) => {
                    this._oppLabelMap[f.value] = f.label;
                    return { label: `${f.label} (${f.value})`, value: f.value };
                })
                .sort((a, b) => a.label.localeCompare(b.label));
            this._pmtFields = pmtData
                .map((f) => {
                    this._pmtLabelMap[f.value] = f.label;
                    return { label: `${f.label} (${f.value})`, value: f.value };
                })
                .sort((a, b) => a.label.localeCompare(b.label));
            this._fieldLoadError = "";
            /* eslint-disable-next-line no-console */
            console.log(
                `PaymentMapping: loaded ${this._oppFields.length} Opp fields, ${this._pmtFields.length} Pmt fields`
            );
        } else if (error) {
            this._fieldLoadError = "Unable to load field options.";
            /* eslint-disable-next-line no-console */
            console.error("PaymentMapping field load error:", JSON.stringify(error));
        }
    }

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

    get hasFieldLoadError() {
        return !!this._fieldLoadError;
    }

    get showEmptyMessage() {
        return !this.hasRecords && !this._isCreating && !this._isEditing;
    }

    get displayRecords() {
        if (!this._settings) {
            return [];
        }
        return this._settings.map((r) => ({
            ...r,
            oppFieldDisplay: this._formatFieldDisplay(r.Opportunity_Field__c, this._oppLabelMap),
            pmtFieldDisplay: this._formatFieldDisplay(r.Payment_Field__c, this._pmtLabelMap),
        }));
    }

    get columns() {
        if (this._canEdit) {
            return [...DATA_COLUMNS, ACTION_COLUMN];
        }
        return DATA_COLUMNS;
    }

    get oppFieldOptions() {
        return this._oppFields;
    }

    get pmtFieldOptions() {
        return this._pmtFields;
    }

    // ─── Create ─────────────────────────────────────────────────────────

    handleNew() {
        this._isCreating = true;
        this._isEditing = false;
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
            const fieldValues = {
                ...this._newRecord,
                Name: this._newRecord.Opportunity_Field__c,
            };
            await createListSetting({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues,
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

    // ─── Edit ───────────────────────────────────────────────────────────

    handleEdit(row) {
        this._isEditing = true;
        this._isCreating = false;
        this._editRecord = {
            Id: row.Id,
            Opportunity_Field__c: row.Opportunity_Field__c || "",
            Payment_Field__c: row.Payment_Field__c || "",
        };
    }

    handleCancelEdit() {
        this._isEditing = false;
    }

    handleEditOpportunityFieldChange(event) {
        this._editRecord = { ...this._editRecord, Opportunity_Field__c: event.detail.value };
    }

    handleEditPaymentFieldChange(event) {
        this._editRecord = { ...this._editRecord, Payment_Field__c: event.detail.value };
    }

    async handleSaveEdit() {
        if (!this._editRecord.Opportunity_Field__c || !this._editRecord.Payment_Field__c) {
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
            const { Id, ...fieldValues } = this._editRecord;
            await updateListSetting({
                settingsObjectName: SETTINGS_OBJECT,
                recordId: Id,
                fieldValues,
            });
            await refreshApex(this._wiredResult);
            this._isEditing = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Payment field mapping updated.",
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

    // ─── Row Actions ────────────────────────────────────────────────────

    async handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action === "edit") {
            this.handleEdit(row);
        } else if (action === "delete") {
            try {
                await deleteListSetting({
                    settingsObjectName: SETTINGS_OBJECT,
                    recordId: row.Id,
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

    // ─── Helpers ────────────────────────────────────────────────────────

    _formatFieldDisplay(apiName, labelMap) {
        if (!apiName) {
            return "";
        }
        const label = labelMap[apiName];
        return label ? `${label} (${apiName})` : apiName;
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
