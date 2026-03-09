import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";

const SETTINGS_OBJECT = "Error_Settings__c";

export default class StgPanelDuplicateRules extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        respectDupeRules: "Respect Duplicate Rule Settings",
    };

    get sectionDescription() {
        return "Salesforce Duplicate Rules detect and prevent duplicate records when data is created or updated. These settings control whether NPPatch honors those rules during automated processing — such as when creating Contacts from donations, generating Household Accounts, or importing data.";
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

    get respectDupeRulesValue() {
        return this._workingCopy?.Respect_Duplicate_Rule_Settings__c || false;
    }

    handleRespectDupeRulesChange(event) {
        this._workingCopy = {
            ...this._workingCopy,
            Respect_Duplicate_Rule_Settings__c: event.detail.checked,
        };
    }

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Respect_Duplicate_Rule_Settings__c: this._workingCopy.Respect_Duplicate_Rule_Settings__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Duplicate rule settings saved.", variant: "success" })
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
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return "An unexpected error occurred.";
    }
}
