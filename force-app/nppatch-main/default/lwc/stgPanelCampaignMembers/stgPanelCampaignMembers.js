import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";

import stgNavDonations from "@salesforce/label/c.stgNavDonations";
import stgLabelOppCampMembers from "@salesforce/label/c.stgLabelOppCampMembers";

const SETTINGS_OBJECT = "Contacts_And_Orgs_Settings__c";

export default class StgPanelCampaignMembers extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavDonations,
        pageLabel: stgLabelOppCampMembers,
        autoCampaignMember: "Automatic Campaign Member Management",
        respondedStatus: "Campaign Member Responded Status",
        nonRespondedStatus: "Campaign Member Non-Responded Status",
    };

    get sectionDescription() {
        return "When an Opportunity is linked to a Campaign, the associated Campaign Member\u2019s status can be updated automatically to reflect their response. These settings control that automation and define the default statuses used.";
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

    get isAutoManagementDisabled() {
        return !this._workingCopy?.Automatic_Campaign_Member_Management__c;
    }

    handleAutoChange(event) {
        this._workingCopy.Automatic_Campaign_Member_Management__c = event.detail.checked;
    }

    handleRespondedChange(event) {
        this._workingCopy.Campaign_Member_Responded_Status__c = event.detail.value;
    }

    handleNonRespondedChange(event) {
        this._workingCopy.Campaign_Member_Non_Responded_Status__c = event.detail.value;
    }

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Automatic_Campaign_Member_Management__c:
                        this._workingCopy.Automatic_Campaign_Member_Management__c,
                    Campaign_Member_Responded_Status__c:
                        this._workingCopy.Campaign_Member_Responded_Status__c,
                    Campaign_Member_Non_Responded_Status__c:
                        this._workingCopy.Campaign_Member_Non_Responded_Status__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Campaign Member settings saved.", variant: "success" })
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
