import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getGAUOptions from "@salesforce/apex/NppatchSettingsController.getGAUOptions";

import stgHelpDefaultAllocationsEnabled from "@salesforce/label/c.stgHelpDefaultAllocationsEnabled";
import stgHelpDefaultGAU from "@salesforce/label/c.stgHelpDefaultGAU";

const SETTINGS_OBJECT = "Allocations_Settings__c";

export default class StgPanelAllocations extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;
    _gauOptions = [];

    labels = {
        helpDefaultAllocEnabled: stgHelpDefaultAllocationsEnabled,
        helpDefaultGAU: stgHelpDefaultGAU,
        defaultAllocEnabled: "Default Allocations Enabled",
        defaultGAU: "Default General Accounting Unit",
    };

    get sectionDescription() {
        return "Allocations distribute Opportunity amounts across General Accounting Units (GAUs) for fund tracking. Enable default allocations to automatically assign a GAU to new Opportunities.";
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

    @wire(getGAUOptions)
    wiredGAUOptions({ data }) {
        if (data) {
            this._gauOptions = data;
        }
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get defaultGAUDisabled() {
        return !this._workingCopy.Default_Allocations_Enabled__c;
    }

    get gauComboboxOptions() {
        return this._gauOptions;
    }

    get hasGAUOptions() {
        return this._gauOptions.length > 0;
    }

    get gauPlaceholder() {
        if (this._gauOptions.length === 0) {
            return "-- No General Accounting Units found. --";
        }
        return "Select a General Accounting Unit...";
    }

    handleDefaultAllocEnabledChange(event) {
        this._workingCopy = {
            ...this._workingCopy,
            Default_Allocations_Enabled__c: event.detail.checked,
            Default__c: event.detail.checked ? this._workingCopy.Default__c : null,
        };
    }

    handleDefaultGAUChange(event) {
        this._workingCopy = {
            ...this._workingCopy,
            Default__c: event.detail.value || null,
        };
    }

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Default_Allocations_Enabled__c: this._workingCopy.Default_Allocations_Enabled__c,
                    Default__c: this._workingCopy.Default__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Allocation settings saved.", variant: "success" })
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
