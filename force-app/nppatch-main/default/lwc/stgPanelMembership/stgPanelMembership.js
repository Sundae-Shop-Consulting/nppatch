import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";

import stgHelpMembershipGracePeriod from "@salesforce/label/c.stgHelpMembershipGracePeriod";

const SETTINGS_OBJECT = "Households_Settings__c";

export default class StgPanelMembership extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        helpGracePeriod: stgHelpMembershipGracePeriod,
        gracePeriod: "Membership Grace Period",
    };

    get sectionDescription() {
        return "Memberships track recurring organizational relationships such as annual dues or subscriptions. The grace period defines how many days past expiration a membership is still considered current for reporting purposes.";
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

    get gracePeriodValue() {
        return this._workingCopy?.Membership_Grace_Period__c;
    }

    handleGracePeriodChange(event) {
        this._workingCopy.Membership_Grace_Period__c = event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Membership_Grace_Period__c: this._workingCopy.Membership_Grace_Period__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Membership settings saved.", variant: "success" })
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
