import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getRecordTypeOptions from "@salesforce/apex/NppatchSettingsController.getRecordTypeOptions";

import stgNavPeople from "@salesforce/label/c.stgNavPeople";
import stgNavAccountModel from "@salesforce/label/c.stgNavAccountModel";
import stgHelpAccountModel from "@salesforce/label/c.stgHelpAccountModel";
import stgHelpHHAccountRTID from "@salesforce/label/c.stgHelpHHAccountRTID";
import stgHelpOneToOneRTID from "@salesforce/label/c.stgHelpOneToOneRTID";
import stgLabelNone from "@salesforce/label/c.stgLabelNone";

const SETTINGS_OBJECT = "Contacts_And_Orgs_Settings__c";

const ACCOUNT_MODEL_OPTIONS = [
    { label: "Household Account", value: "Household Account" },
    { label: "One-to-One", value: "One-to-One" },
    { label: "Individual", value: "Individual" },
];

export default class StgPanelAccountModel extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _accountRecordTypes = [];
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavPeople,
        pageLabel: stgNavAccountModel,
        helpAccountModel: stgHelpAccountModel,
        helpHHAccountRT: stgHelpHHAccountRTID,
        helpOneToOneRT: stgHelpOneToOneRTID,
        none: stgLabelNone,
        accountProcessor: "Account Model",
        hhAccountRecordType: "Household Account Record Type",
        oneToOneRecordType: "One-to-One Record Type",
    };

    accountModelOptions = ACCOUNT_MODEL_OPTIONS;

    get sectionDescription() {
        return "The Account model determines how Contacts relate to Accounts. Household Accounts group related individuals (such as a family) under a single Account. One-to-One creates a dedicated Account per Contact. Individual uses a single shared bucket Account for all Contacts without their own.";
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

    @wire(getRecordTypeOptions, { sObjectApiName: "Account" })
    wiredRecordTypes({ data, error }) {
        if (data) {
            this._accountRecordTypes = data.map((opt) => ({
                label: opt.label,
                value: opt.value,
            }));
        } else if (error) {
            this._accountRecordTypes = [];
        }
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get accountRecordTypeOptionsWithNone() {
        return [{ label: this.labels.none, value: "" }, ...this._accountRecordTypes];
    }

    handleAccountModelChange(event) {
        this._workingCopy.Account_Processor__c = event.detail.value;
    }

    handleHHRecordTypeChange(event) {
        this._workingCopy.HH_Account_RecordTypeID__c = event.detail.value || null;
    }

    handleOneToOneRecordTypeChange(event) {
        this._workingCopy.One_to_One_RecordTypeID__c = event.detail.value || null;
    }

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Account_Processor__c: this._workingCopy.Account_Processor__c,
                    HH_Account_RecordTypeID__c: this._workingCopy.HH_Account_RecordTypeID__c,
                    One_to_One_RecordTypeID__c: this._workingCopy.One_to_One_RecordTypeID__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Account model settings saved.", variant: "success" })
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
