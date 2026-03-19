import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getListSettings from "@salesforce/apex/NppatchSettingsController.getListSettings";
import createListSetting from "@salesforce/apex/NppatchSettingsController.createListSetting";
import updateListSetting from "@salesforce/apex/NppatchSettingsController.updateListSetting";
import deleteListSetting from "@salesforce/apex/NppatchSettingsController.deleteListSetting";
import getFieldDescribes from "@salesforce/apex/NppatchSettingsController.getFieldDescribes";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

const SETTINGS_OBJECT = "Opportunity_Naming_Settings__c";
const OTHER_VALUE = "__other__";
const DO_NOT_RENAME = "";

const NAME_FORMAT_OPTIONS = [
    { label: "- do not rename -", value: DO_NOT_RENAME },
    {
        label: "{!Account.Name} {!Amount} {!RecordType.Name} {!CloseDate}",
        value: "{!Account.Name} {!Amount} {!RecordType.Name} {!CloseDate}",
    },
    {
        label: "{!Contact.Name} {!Amount} {!RecordType.Name} {!CloseDate} {!Recurring_Donation_Installment_Name__c}",
        value: "{!Contact.Name} {!Amount} {!RecordType.Name} {!CloseDate} {!Recurring_Donation_Installment_Name__c}",
    },
    {
        label: "{!Contact.Name} {!RecordType.Name} {!CloseDate} {!Campaign.Name}",
        value: "{!Contact.Name} {!RecordType.Name} {!CloseDate} {!Campaign.Name}",
    },
    { label: "Other (custom format)", value: OTHER_VALUE },
];

const DATE_FORMAT_OPTIONS = [
    { label: "Default (org locale)", value: "" },
    { label: "yyyy-MM-dd", value: "yyyy-MM-dd" },
    { label: "MM/dd/yyyy", value: "MM/dd/yyyy" },
    { label: "dd/MM/yyyy", value: "dd/MM/yyyy" },
    { label: "MMMM d, yyyy", value: "MMMM d, yyyy" },
    { label: "M/d/yyyy", value: "M/d/yyyy" },
    { label: "Other (custom pattern)", value: OTHER_VALUE },
];

const ATTRIBUTION_OPTIONS = [
    { label: "Both", value: "Both" },
    { label: "Contact Donations", value: "Contact Donations" },
    { label: "Organization Donations", value: "Organization Donations" },
];

const SAMPLE_DATA = {
    "Account.Name": "Acme Foundation",
    "Contact.Name": "Maria Garcia",
    Amount: "$5,000",
    "RecordType.Name": "Donation",
    CloseDate: "2026-03-15",
    "Campaign.Name": "Annual Gala",
    Recurring_Donation_Installment_Name__c: "RD-001 Payment 3",
};

const COLUMNS_ADMIN = [
    { label: "Attribution", fieldName: "Attribution__c", type: "text" },
    { label: "Record Types", fieldName: "recordTypesDisplay", type: "text" },
    { label: "Name Format", fieldName: "nameFormatDisplay", type: "text" },
    { label: "Date Format", fieldName: "Date_Format__c", type: "text" },
    {
        type: "action",
        typeAttributes: {
            rowActions: [
                { label: "Edit", name: "edit" },
                { label: "Delete", name: "delete" },
            ],
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
    _isEditing = false;
    _isSaving = false;
    @track _records = [];
    _hasError = false;
    _errorMessage;
    _wiredListResult;

    @track _newAttribution = "";
    @track _newNameFormat = "";
    @track _newDateFormat = "";
    _newFormatCombo = null;
    _newDateCombo = null;

    @track _editRecord = {};
    _editFormatCombo = null;
    _editDateCombo = null;

    labels = {
        sectionLabel: "Donations",
        pageLabel: "Opportunity Naming",
        description:
            "Opportunity Naming rules control how Opportunity Name fields are automatically generated. Each rule can target specific record types and attribution types. The name format uses merge fields from the Opportunity \u2014 for example, '{!Account.Name} {!Amount} {!CloseDate}' generates names like 'Acme Corp $500 2024-01-15.'",
    };

    attributionOptions = ATTRIBUTION_OPTIONS;
    nameFormatOptions = NAME_FORMAT_OPTIONS;
    dateFormatOptions = DATE_FORMAT_OPTIONS;
    customFormatPlaceholder = "{!Account.Name} {!Amount} {!CloseDate}";

    @wire(getListSettings, { settingsObjectName: SETTINGS_OBJECT })
    wiredListSettings(result) {
        this._wiredListResult = result;
        if (result.data) {
            this._records = result.data.map((r) => ({
                ...r,
                recordTypesDisplay: r.Opportunity_Record_Types__c ? r.Opportunity_Record_Types__c : "all record types",
                nameFormatDisplay: r.Opportunity_Name_Format__c ? r.Opportunity_Name_Format__c : "- do not rename -",
            }));
            this._hasError = false;
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    _oppFieldNames = new Set();

    @wire(getFieldDescribes, { sObjectApiName: "Opportunity" })
    wiredFieldDescribes({ data }) {
        if (data) {
            this._oppFieldNames = new Set(data.map((f) => f.value.toLowerCase()));
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

    get actionBarClass() {
        return this.hasRecords ? "action-bar" : "action-bar-centered";
    }

    get isSaveDisabled() {
        return this._isSaving || !this._newAttribution;
    }

    get isEditSaveDisabled() {
        return this._isSaving || !this._editRecord.Attribution__c;
    }

    // ─── Name Format combobox (create) ──────────────────────────────────

    get newFormatComboValue() {
        if (this._newFormatCombo !== null) {
            return this._newFormatCombo;
        }
        return this._resolveComboValue(this._newNameFormat);
    }

    get isNewCustomFormat() {
        return this.newFormatComboValue === OTHER_VALUE;
    }

    get isNewPreviewUnavailable() {
        return (this.isNewCustomFormat || this.isNewCustomDate) && this._newNameFormat;
    }

    get newFormatPreview() {
        if (this.isNewCustomFormat || this.isNewCustomDate) {
            return "";
        }
        return this._renderPreview(this._newNameFormat, this._newDateFormat);
    }

    get newFormatWarnings() {
        if (!this.isNewCustomFormat) {
            return "";
        }
        return this._validateTokens(this._newNameFormat);
    }

    // ─── Date Format combobox (create) ─────────────────────────────────

    get newDateComboValue() {
        if (this._newDateCombo !== null) {
            return this._newDateCombo;
        }
        return this._resolveDateComboValue(this._newDateFormat);
    }

    get isNewCustomDate() {
        return this.newDateComboValue === OTHER_VALUE;
    }

    // ─── Name Format combobox (edit) ────────────────────────────────────

    get editFormatComboValue() {
        if (this._editFormatCombo !== null) {
            return this._editFormatCombo;
        }
        return this._resolveComboValue(this._editRecord.Opportunity_Name_Format__c || "");
    }

    get isEditCustomFormat() {
        return this.editFormatComboValue === OTHER_VALUE;
    }

    get isEditPreviewUnavailable() {
        return (
            (this.isEditCustomFormat || this.isEditCustomDate) && (this._editRecord.Opportunity_Name_Format__c || "")
        );
    }

    get editFormatPreview() {
        if (this.isEditCustomFormat || this.isEditCustomDate) {
            return "";
        }
        return this._renderPreview(
            this._editRecord.Opportunity_Name_Format__c || "",
            this._editRecord.Date_Format__c || ""
        );
    }

    get editFormatWarnings() {
        if (!this.isEditCustomFormat) {
            return "";
        }
        return this._validateTokens(this._editRecord.Opportunity_Name_Format__c || "");
    }

    // ─── Date Format combobox (edit) ────────────────────────────────────

    get editDateComboValue() {
        if (this._editDateCombo !== null) {
            return this._editDateCombo;
        }
        return this._resolveDateComboValue(this._editRecord.Date_Format__c || "");
    }

    get isEditCustomDate() {
        return this.editDateComboValue === OTHER_VALUE;
    }

    // ─── Create form handlers ───────────────────────────────────────────

    handleNewClick() {
        this._isCreating = true;
        this._isEditing = false;
        this._newAttribution = "";
        this._newNameFormat = "";
        this._newDateFormat = "";
        this._newFormatCombo = null;
        this._newDateCombo = null;
    }

    handleCancelCreate() {
        this._isCreating = false;
    }

    handleAttributionChange(event) {
        this._newAttribution = event.detail.value;
    }

    handleFormatComboChange(event) {
        const selected = event.detail.value;
        this._newFormatCombo = selected;
        if (selected === OTHER_VALUE) {
            // Keep current value so the user can edit it as a starting point
        } else {
            this._newNameFormat = selected;
        }
    }

    handleCustomFormatChange(event) {
        this._newNameFormat = event.detail.value;
    }

    handleDateComboChange(event) {
        const selected = event.detail.value;
        this._newDateCombo = selected;
        if (selected !== OTHER_VALUE) {
            this._newDateFormat = selected;
        }
    }

    handleCustomDateChange(event) {
        this._newDateFormat = event.detail.value;
    }

    async handleSaveCreate() {
        this._isSaving = true;
        try {
            const fieldValues = {
                Name: new Date().toISOString(),
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

    // ─── Edit form handlers ─────────────────────────────────────────────

    handleEdit(row) {
        this._isEditing = true;
        this._isCreating = false;
        this._editFormatCombo = null;
        this._editDateCombo = null;
        this._editRecord = {
            Id: row.Id,
            Attribution__c: row.Attribution__c || "",
            Opportunity_Name_Format__c: row.Opportunity_Name_Format__c || "",
            Date_Format__c: row.Date_Format__c || "",
            Opportunity_Record_Types__c: row.Opportunity_Record_Types__c || "",
        };
    }

    handleCancelEdit() {
        this._isEditing = false;
    }

    handleEditAttributionChange(event) {
        this._editRecord = { ...this._editRecord, Attribution__c: event.detail.value };
    }

    handleEditFormatComboChange(event) {
        const selected = event.detail.value;
        this._editFormatCombo = selected;
        if (selected === OTHER_VALUE) {
            // Keep current value so the user can edit it as a starting point
        } else {
            this._editRecord = { ...this._editRecord, Opportunity_Name_Format__c: selected };
        }
    }

    handleEditCustomFormatChange(event) {
        this._editRecord = { ...this._editRecord, Opportunity_Name_Format__c: event.detail.value };
    }

    handleEditDateComboChange(event) {
        const selected = event.detail.value;
        this._editDateCombo = selected;
        if (selected !== OTHER_VALUE) {
            this._editRecord = { ...this._editRecord, Date_Format__c: selected };
        }
    }

    handleEditCustomDateChange(event) {
        this._editRecord = { ...this._editRecord, Date_Format__c: event.detail.value };
    }

    async handleSaveEdit() {
        this._isSaving = true;
        try {
            const { Id, ...fieldValues } = this._editRecord;
            await updateListSetting({
                settingsObjectName: SETTINGS_OBJECT,
                recordId: Id,
                fieldValues,
            });
            await refreshApex(this._wiredListResult);
            this._isEditing = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Opportunity naming setting updated.",
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

    // ─── Row actions ────────────────────────────────────────────────────

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action === "edit") {
            this.handleEdit(row);
        } else if (action === "delete") {
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

    // ─── Helpers ────────────────────────────────────────────────────────

    _resolveDateComboValue(format) {
        if (!format) {
            return "";
        }
        const known = DATE_FORMAT_OPTIONS.find((o) => o.value === format && o.value !== OTHER_VALUE);
        return known ? format : OTHER_VALUE;
    }

    _resolveComboValue(format) {
        if (!format) {
            return DO_NOT_RENAME;
        }
        const known = NAME_FORMAT_OPTIONS.find((o) => o.value === format && o.value !== OTHER_VALUE);
        return known ? format : OTHER_VALUE;
    }

    _renderPreview(format, dateFormat) {
        if (!format) {
            return "";
        }
        const formattedDate = this._formatSampleDate(dateFormat);
        return format.replace(/\{!([^}]+)\}/g, (_, field) => {
            if (field === "CloseDate") {
                return formattedDate;
            }
            return SAMPLE_DATA[field] || `{!${field}}`;
        });
    }

    _formatSampleDate(pattern) {
        // Sample date: March 15, 2026
        const formats = {
            "yyyy-MM-dd": "2026-03-15",
            "MM/dd/yyyy": "03/15/2026",
            "dd/MM/yyyy": "15/03/2026",
            "MMMM d, yyyy": "March 15, 2026",
            "M/d/yyyy": "3/15/2026",
        };
        return formats[pattern] || "2026-03-15";
    }

    _validateTokens(format) {
        if (!format || this._oppFieldNames.size === 0) {
            return "";
        }
        const tokens = [];
        const regex = /\{!([^}]+)\}/g;
        let match;
        while ((match = regex.exec(format)) !== null) {
            tokens.push(match[1]);
        }
        const unknown = tokens.filter((t) => {
            // Relationship traversals (Account.Name) can't be validated with a single describe
            if (t.includes(".")) {
                return false;
            }
            return !this._oppFieldNames.has(t.toLowerCase());
        });
        if (unknown.length === 0) {
            return "";
        }
        return `Unrecognized field${unknown.length > 1 ? "s" : ""}: ${unknown.join(", ")}`;
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
