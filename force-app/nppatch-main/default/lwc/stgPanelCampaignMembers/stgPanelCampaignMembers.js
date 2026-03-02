import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

import stgNavDonations from "@salesforce/label/c.stgNavDonations";
import stgLabelOppCampMembers from "@salesforce/label/c.stgLabelOppCampMembers";
import stgBtnEdit from "@salesforce/label/c.stgBtnEdit";
import stgBtnSave from "@salesforce/label/c.stgBtnSave";
import stgBtnCancel from "@salesforce/label/c.stgBtnCancel";

const SETTINGS_OBJECT = "Contacts_And_Orgs_Settings__c";

export default class StgPanelCampaignMembers extends LightningElement {
    _isAdmin = false;
    _isEditMode = false;
    _isSaving = false;
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavDonations,
        pageLabel: stgLabelOppCampMembers,
        edit: stgBtnEdit,
        save: stgBtnSave,
        cancel: stgBtnCancel,
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

    get canEdit() {
        return this._isAdmin && !this._isEditMode;
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get autoCampaignMemberDisplay() {
        return this._settings?.Automatic_Campaign_Member_Management__c ? "Enabled" : "Disabled";
    }

    get respondedStatusDisplay() {
        return this._settings?.Campaign_Member_Responded_Status__c || "—";
    }

    get nonRespondedStatusDisplay() {
        return this._settings?.Campaign_Member_Non_Responded_Status__c || "—";
    }

    handleEdit() {
        this._workingCopy = { ...this._settings };
        this._isEditMode = true;
    }

    handleCancel() {
        this._workingCopy = {};
        this._isEditMode = false;
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

    async handleSave() {
        this._isSaving = true;
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
            this._isEditMode = false;
            this._workingCopy = {};
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Campaign Member settings saved.", variant: "success" })
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
        if (error?.body?.message) {return error.body.message;}
        if (error?.message) {return error.message;}
        return "An unexpected error occurred.";
    }
}
