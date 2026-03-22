import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";

import stgNavRelationships from "@salesforce/label/c.stgNavRelationships";
import stgNavAffiliations from "@salesforce/label/c.stgNavAffiliations";
import stgHelpAutoAffil from "@salesforce/label/c.stgHelpAutoAffil";

const SETTINGS_OBJECT = "Affiliations_Settings__c";

export default class StgPanelAffiliations extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavRelationships,
        pageLabel: stgNavAffiliations,
        helpAutoAffil: stgHelpAutoAffil,
        autoAffiliation: "Automatic Affiliation Creation",
    };

    get sectionDescription() {
        return "Affiliations track the connections between people and organizations, such as employment, board service, or enrollment. When enabled, an Affiliation record is automatically created whenever a Contact\u2019s primary Account changes, preserving a history of organizational relationships.";
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

    handleAutoAffilChange(event) {
        this._workingCopy.Automatic_Affiliation_Creation_Turned_On__c = event.detail.checked;
    }

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Automatic_Affiliation_Creation_Turned_On__c:
                        this._workingCopy.Automatic_Affiliation_Creation_Turned_On__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Affiliation settings saved.", variant: "success" })
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
