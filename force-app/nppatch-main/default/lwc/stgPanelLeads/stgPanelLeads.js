import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";

import stgNavPeople from "@salesforce/label/c.stgNavPeople";
import stgNavLeads from "@salesforce/label/c.stgNavLeads";
import stgHelpLeadConvert from "@salesforce/label/c.stgHelpLeadConvert";

const SETTINGS_OBJECT = "Contacts_And_Orgs_Settings__c";

export default class StgPanelLeads extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavPeople,
        pageLabel: stgNavLeads,
        helpLeadConvert: stgHelpLeadConvert,
        defaultOppOnConvert: "Do Not Create Opportunity on Lead Convert",
    };

    get sectionDescription() {
        return "Lead conversion creates or updates a Contact and Account from an incoming Lead. By default, Salesforce also creates a new Opportunity during this process. If your organization prefers to create Opportunities separately, you can disable that here.";
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

    handleDefaultOppChange(event) {
        this._workingCopy.Default_Opp_on_Convert__c = event.detail.checked;
    }

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Default_Opp_on_Convert__c: this._workingCopy.Default_Opp_on_Convert__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Lead settings saved.", variant: "success" })
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
