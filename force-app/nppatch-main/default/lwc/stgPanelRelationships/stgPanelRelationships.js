import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";

import stgNavRelationships from "@salesforce/label/c.stgNavRelationships";

const SETTINGS_OBJECT = "Relationship_Settings__c";

const RECIPROCAL_METHOD_OPTIONS = [
    { label: "List Setting", value: "List Setting" },
    { label: "Value Inversion", value: "Value Inversion" },
];

export default class StgPanelRelationships extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavRelationships,
        reciprocalMethod: "Reciprocal Method",
        helpReciprocalMethod:
            "Select the method used to generate the reciprocal relationship. List Setting uses the Relationship Lookup custom setting to determine the reciprocal. Value Inversion attempts to invert the type, e.g. Parent-Child to Child-Parent.",
        genderField: "Gender Field",
        helpGenderField:
            "An optional Contact field to use for Gender. It must be a text or picklist field with recognized values (Male, Female, Non-Binary, etc.). Used by Reciprocal Relationships to select gendered reciprocal types.",
        allowDuplicates: "Allow Auto-Created Duplicates",
        helpAllowDuplicates:
            "When checked, auto-create relationship settings may create duplicate relationships between the same two Contacts.",
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
            this._workingCopy = { ...result.data };
            this._hasError = false;
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    get isLoading() {
        return !this._settings && !this._hasError;
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

    @api
    async save() {
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
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Relationship settings saved.", variant: "success" })
            );
            return true;
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({ title: "Error", message: this._extractError(error), variant: "error" })
            );
            return false;
        }
    }

    @api
    reset() {
        this._workingCopy = { ...this._settings };
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
