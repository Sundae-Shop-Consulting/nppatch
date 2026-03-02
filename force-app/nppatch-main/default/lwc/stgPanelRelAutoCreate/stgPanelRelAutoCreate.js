import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getListSettings from "@salesforce/apex/NppatchSettingsController.getListSettings";
import createListSetting from "@salesforce/apex/NppatchSettingsController.createListSetting";
import deleteListSetting from "@salesforce/apex/NppatchSettingsController.deleteListSetting";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

const SETTINGS_OBJECT = "Relationship_Auto_Create__c";

const OBJECT_OPTIONS = [
    { label: "Contact", value: "Contact" },
    { label: "CampaignMember", value: "CampaignMember" },
];

const COLUMNS_ADMIN = [
    { label: "Object", fieldName: "Object__c", type: "text" },
    { label: "Field", fieldName: "Field__c", type: "text" },
    { label: "Relationship Type", fieldName: "Relationship_Type__c", type: "text" },
    { label: "Campaign Types", fieldName: "Campaign_Types__c", type: "text" },
    {
        type: "action",
        typeAttributes: {
            rowActions: [{ label: "Delete", name: "delete" }],
        },
    },
];

const COLUMNS_READ_ONLY = [
    { label: "Object", fieldName: "Object__c", type: "text" },
    { label: "Field", fieldName: "Field__c", type: "text" },
    { label: "Relationship Type", fieldName: "Relationship_Type__c", type: "text" },
    { label: "Campaign Types", fieldName: "Campaign_Types__c", type: "text" },
];

export default class StgPanelRelAutoCreate extends LightningElement {
    _isAdmin = false;
    _isCreating = false;
    _isSaving = false;
    @track _records = [];
    _hasError = false;
    _errorMessage;
    _wiredListResult;

    @track _newObject = "";
    @track _newField = "";
    @track _newRelationshipType = "";
    @track _newCampaignTypes = "";

    labels = {
        sectionLabel: "Relationships",
        pageLabel: "Auto-Create Relationships",
        description:
            "Auto-Create Relationships automatically generate Relationship records when specific lookup fields on Contacts or Campaign Members are populated. For example, you can configure the system to create a relationship when an Emergency Contact field is filled in.",
    };

    objectOptions = OBJECT_OPTIONS;

    @wire(getListSettings, { settingsObjectName: SETTINGS_OBJECT })
    wiredListSettings(result) {
        this._wiredListResult = result;
        if (result.data) {
            this._records = result.data.map((r) => ({ ...r }));
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

    get showCampaignTypes() {
        return this._newObject === "CampaignMember";
    }

    get isSaveDisabled() {
        return this._isSaving || !this._newObject || !this._newField;
    }

    // --- Create form handlers ---

    handleNewClick() {
        this._isCreating = true;
        this._newObject = "";
        this._newField = "";
        this._newRelationshipType = "";
        this._newCampaignTypes = "";
    }

    handleCancelCreate() {
        this._isCreating = false;
    }

    handleObjectChange(event) {
        this._newObject = event.detail.value;
        if (this._newObject !== "CampaignMember") {
            this._newCampaignTypes = "";
        }
    }

    handleFieldChange(event) {
        this._newField = event.detail.value;
    }

    handleRelationshipTypeChange(event) {
        this._newRelationshipType = event.detail.value;
    }

    handleCampaignTypesChange(event) {
        this._newCampaignTypes = event.detail.value;
    }

    async handleSaveCreate() {
        this._isSaving = true;
        try {
            const fieldValues = {
                Object__c: this._newObject,
                Field__c: this._newField,
                Relationship_Type__c: this._newRelationshipType,
            };
            if (this._newObject === "CampaignMember" && this._newCampaignTypes) {
                fieldValues.Campaign_Types__c = this._newCampaignTypes;
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
                    message: "Auto-create relationship setting created.",
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
                    message: "Auto-create relationship setting deleted.",
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
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return "An unexpected error occurred.";
    }
}
