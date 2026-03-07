import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getRecordTypeOptions from "@salesforce/apex/NppatchSettingsController.getRecordTypeOptions";
import getPicklistOptions from "@salesforce/apex/NppatchSettingsController.getPicklistOptions";

import stgHelpPaymentsEnabled from "@salesforce/label/c.stgHelpPaymentsEnabled";
import stgHelpMaxPayments from "@salesforce/label/c.stgHelpMaxPayments";
import stgHelpOppRecTypesNoPayments from "@salesforce/label/c.stgHelpOppRecTypesNoPayments";
import stgHelpOppTypesNoPayments from "@salesforce/label/c.stgHelpOppTypesNoPayments";

const SETTINGS_OBJECT = "Contacts_And_Orgs_Settings__c";

export default class StgPanelPayments extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _oppRecordTypes = [];
    _oppTypes = [];
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        helpPaymentsEnabled: stgHelpPaymentsEnabled,
        helpMaxPayments: stgHelpMaxPayments,
        helpExcludedRecTypes: stgHelpOppRecTypesNoPayments,
        helpExcludedTypes: stgHelpOppTypesNoPayments,
        paymentsEnabled: "Payments Enabled",
        maxPayments: "Maximum Payments",
        excludedRecordTypes: "Excluded Record Types",
        excludedOppTypes: "Excluded Opportunity Types",
    };

    get sectionDescription() {
        return "Payment records track how an Opportunity is fulfilled \u2014 for example, splitting a pledge into monthly installments or recording payment methods. When enabled, Payments are automatically created for new Opportunities. You can exclude specific record types or Opportunity types that don\u2019t need payment tracking.";
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

    @wire(getRecordTypeOptions, { sObjectApiName: "Opportunity" })
    wiredOppRecordTypes({ data, error }) {
        if (data) {
            this._oppRecordTypes = data.map((opt) => ({ label: opt.label, value: opt.value }));
        } else if (error) {
            this._oppRecordTypes = [];
        }
    }

    @wire(getPicklistOptions, { sObjectApiName: "Opportunity", fieldApiName: "Type" })
    wiredOppTypes({ data, error }) {
        if (data) {
            this._oppTypes = data.map((opt) => ({ label: opt.label, value: opt.value }));
        } else if (error) {
            this._oppTypes = [];
        }
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get isPaymentsDisabled() {
        return !this._workingCopy?.Payments_Enabled__c;
    }

    get selectedExcludedRecTypes() {
        return this._parseMultiSelect(this._workingCopy?.Opp_RecTypes_Excluded_for_Payments__c);
    }

    get selectedExcludedOppTypes() {
        return this._parseMultiSelect(this._workingCopy?.Opp_Types_Excluded_for_Payments__c);
    }

    _parseMultiSelect(rawValue) {
        if (!rawValue) {
            return [];
        }
        return rawValue.split(";").filter(Boolean);
    }

    handlePaymentsEnabledChange(event) {
        this._workingCopy.Payments_Enabled__c = event.detail.checked;
    }

    handleMaxPaymentsChange(event) {
        this._workingCopy.Max_Payments__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleExcludedRecTypesChange(event) {
        this._workingCopy.Opp_RecTypes_Excluded_for_Payments__c =
            event.detail.value.join(";");
    }

    handleExcludedOppTypesChange(event) {
        this._workingCopy.Opp_Types_Excluded_for_Payments__c =
            event.detail.value.join(";");
    }

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Payments_Enabled__c: this._workingCopy.Payments_Enabled__c,
                    Max_Payments__c: this._workingCopy.Max_Payments__c,
                    Opp_RecTypes_Excluded_for_Payments__c:
                        this._workingCopy.Opp_RecTypes_Excluded_for_Payments__c || null,
                    Opp_Types_Excluded_for_Payments__c:
                        this._workingCopy.Opp_Types_Excluded_for_Payments__c || null,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Payment settings saved.", variant: "success" })
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
