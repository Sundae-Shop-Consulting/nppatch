import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getListSettings from "@salesforce/apex/NppatchSettingsController.getListSettings";
import createListSetting from "@salesforce/apex/NppatchSettingsController.createListSetting";
import deleteListSetting from "@salesforce/apex/NppatchSettingsController.deleteListSetting";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

const SETTINGS_OBJECT = "Opportunity_Naming_Settings__c";

const ATTRIBUTION_OPTIONS = [
    { label: "Both", value: "Both" },
    { label: "Contact Donations", value: "Contact Donations" },
    { label: "Organization Donations", value: "Organization Donations" },
];

const COLUMNS_ADMIN = [
    { label: "Attribution", fieldName: "Attribution__c", type: "text" },
    { label: "Record Types", fieldName: "recordTypesDisplay", type: "text" },
    { label: "Name Format", fieldName: "nameFormatDisplay", type: "text" },
    { label: "Date Format", fieldName: "Date_Format__c", type: "text" },
    {
        type: "action",
        typeAttributes: {
            rowActions: [{ label: "Delete", name: "delete" }],
        },
    },
];

const COLUMNS_READ_ONLY = [
    { label: "Attribution", fieldName: "Attribution__c", type: "text" },
    { label: "Record Types", fieldName: "recordTypesDisplay", type: "text" },
    { label: "Name Format", fieldName: "nameFormatDisplay", type: "text" },
    { label: "Date Format", fieldName: "Date_Format__c", type: "text" },
];

export default class StgPanelOppNaming extends LightningElement {
    _isAdmin = false;
    _isCreating = false;
    _isSaving = false;
    @track _records = [];
    _hasError = false;
    _errorMessage;
    _wiredListResult;

    @track _newAttribution = "";
    @track _newNameFormat = "";
    @track _newDateFormat = "";

    labels = {
        sectionLabel: "Donations",
        pageLabel: "Opportunity Naming",
        description:
            "Opportunity Naming rules control how Opportunity Name fields are automatically generated. Each rule can target specific record types and attribution types. The name format uses merge fields from the Opportunity \u2014 for example, '{!Account.Name} {!Amount} {!CloseDate}' generates names like 'Acme Corp $500 2024-01-15.'",
    };

    attributionOptions = ATTRIBUTION_OPTIONS;

    @wire(getListSettings, { settingsObjectName: SETTINGS_OBJECT })
    wiredListSettings(result) {
        this._wiredListResult = result;
        if (result.data) {
            this._records = result.data.map((r) => ({
                ...r,
                recordTypesDisplay: r.Opportunity_Record_Types__c
                    ? r.Opportunity_Record_Types__c
                    : "all record types",
                nameFormatDisplay: r.Opportunity_Name_Format__c
                    ? r.Opportunity_Name_Format__c
                    : "do not rename",
            }));
            this._hasError = false;
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    @wire(isAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this._isAdmin = data;
        }
    }

    get isLoading() {
        return !this._wiredListResult?.data && !this._hasError;
    }

    get isReady() {
        return !!this._wiredListResult?.data;
    }

    get hasRecords() {
        return this._records.length > 0;
    }

    get columns() {
        return this._isAdmin ? COLUMNS_ADMIN : COLUMNS_READ_ONLY;
    }

    get isSaveDisabled() {
        return this._isSaving || !this._newAttribution;
    }

    // --- Create form handlers ---

    handleNewClick() {
        this._isCreating = true;
        this._newAttribution = "";
        this._newNameFormat = "";
        this._newDateFormat = "";
    }

    handleCancelCreate() {
        this._isCreating = false;
    }

    handleAttributionChange(event) {
        this._newAttribution = event.detail.value;
    }

    handleNameFormatChange(event) {
        this._newNameFormat = event.detail.value;
    }

    handleDateFormatChange(event) {
        this._newDateFormat = event.detail.value;
    }

    async handleSaveCreate() {
        this._isSaving = true;
        try {
            const fieldValues = {
                Attribution__c: this._newAttribution,
            };
            if (this._newNameFormat) {
                fieldValues.Opportunity_Name_Format__c = this._newNameFormat;
            }
            if (this._newDateFormat) {
                fieldValues.Date_Format__c = this._newDateFormat;
            }
            await createListSetting({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: fieldValues,
            });
            await refreshApex(this._wiredListResult);
            this._isCreating = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Opportunity naming setting created.",
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

    // --- Row action (delete) ---

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        if (action.name === "delete") {
            this._handleDelete(row);
        }
    }

    async _handleDelete(row) {
        try {
            await deleteListSetting({
                settingsObjectName: SETTINGS_OBJECT,
                recordId: row.Id,
            });
            await refreshApex(this._wiredListResult);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Opportunity naming setting deleted.",
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
        }
    }

    _extractError(error) {
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return "An unexpected error occurred.";
    }
}
