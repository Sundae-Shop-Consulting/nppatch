import { LightningElement, wire, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import stgNavRelationships from "@salesforce/label/c.stgNavRelationships";
import stgBtnEdit from "@salesforce/label/c.stgBtnEdit";
import stgBtnSave from "@salesforce/label/c.stgBtnSave";
import stgBtnCancel from "@salesforce/label/c.stgBtnCancel";

const SETTINGS_OBJECT = "Relationship_Settings__c";

const RECIPROCAL_METHOD_OPTIONS = [
    { label: "List Setting", value: "List Setting" },
    { label: "Value Inversion", value: "Value Inversion" },
];

export default class StgPanelRelationships extends LightningElement {
    @api isAdmin = false;
    _isEditMode = false;
    _isSaving = false;
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavRelationships,
        edit: stgBtnEdit,
        save: stgBtnSave,
        cancel: stgBtnCancel,
        reciprocalMethod: "Reciprocal Method",
        helpReciprocalMethod: "Select the method used to generate the reciprocal relationship. List Setting uses the Relationship Lookup custom setting to determine the reciprocal. Value Inversion attempts to invert the type, e.g. Parent-Child to Child-Parent.",
        genderField: "Gender Field",
        helpGenderField: "An optional Contact field to use for Gender. It must be a text or picklist field with recognized values (Male, Female, Non-Binary, etc.). Used by Reciprocal Relationships to select gendered reciprocal types.",
        allowDuplicates: "Allow Auto-Created Duplicates",
        helpAllowDuplicates: "When checked, auto-create relationship settings may create duplicate relationships between the same two Contacts.",
    };

    reciprocalMethodOptions = RECIPROCAL_METHOD_OPTIONS;

    get sectionDescription() {
        return "Relationships track connections between Contacts, such as family members, coworkers, or friends. These settings control how reciprocal relationships are created and whether duplicate auto-created relationships are allowed.";
    }

    @wire(getSettings, { settingsObjectName: SETTINGS_OBJECT })
    wiredSettings(result) {
        this._wiredSettingsResult = result;
        if (result.data) {
            this._settings = { ...result.data };
            this._hasError = false;
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    get canEdit() {
        return this.isAdmin && !this._isEditMode;
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get genderFieldDisplay() {
        return this._settings?.Gender_Field__c || "";
    }

    get genderFieldValue() {
        return this._workingCopy?.Gender_Field__c || "";
    }

    get allowDuplicatesValue() {
        return this._workingCopy?.Allow_AutoCreated_Duplicates__c || false;
    }

    handleEdit() {
        this._workingCopy = { ...this._settings };
        this._isEditMode = true;
    }

    handleCancel() {
        this._workingCopy = {};
        this._isEditMode = false;
    }

    handleReciprocalMethodChange(event) {
        this._workingCopy.Reciprocal_Method__c = event.detail.value;
    }

    handleGenderFieldChange(event) {
        this._workingCopy.Gender_Field__c = event.detail.value;
    }

    handleAllowDuplicatesChange(event) {
        this._workingCopy.Allow_AutoCreated_Duplicates__c = event.detail.checked;
    }

    async handleSave() {
        this._isSaving = true;
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Reciprocal_Method__c: this._workingCopy.Reciprocal_Method__c,
                    Gender_Field__c: this._workingCopy.Gender_Field__c,
                    Allow_AutoCreated_Duplicates__c: this._workingCopy.Allow_AutoCreated_Duplicates__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this._isEditMode = false;
            this._workingCopy = {};
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Relationship settings saved.", variant: "success" })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({ title: "Error", message: this._extractError(error), variant: "error" })
            );
        } finally {
            this._isSaving = false;
        }
    }

    _extractError(error) {
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return "An unexpected error occurred.";
    }
}
