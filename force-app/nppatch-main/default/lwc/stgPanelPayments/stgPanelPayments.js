import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getRecordTypeOptions from "@salesforce/apex/NppatchSettingsController.getRecordTypeOptions";
import getPicklistOptions from "@salesforce/apex/NppatchSettingsController.getPicklistOptions";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

import stgNavDonations from "@salesforce/label/c.stgNavDonations";
import stgNavPayments from "@salesforce/label/c.stgNavPayments";
import stgHelpPaymentsEnabled from "@salesforce/label/c.stgHelpPaymentsEnabled";
import stgHelpMaxPayments from "@salesforce/label/c.stgHelpMaxPayments";
import stgHelpOppRecTypesNoPayments from "@salesforce/label/c.stgHelpOppRecTypesNoPayments";
import stgHelpOppTypesNoPayments from "@salesforce/label/c.stgHelpOppTypesNoPayments";
import stgBtnEdit from "@salesforce/label/c.stgBtnEdit";
import stgBtnSave from "@salesforce/label/c.stgBtnSave";
import stgBtnCancel from "@salesforce/label/c.stgBtnCancel";
import stgLabelNone from "@salesforce/label/c.stgLabelNone";

const SETTINGS_OBJECT = "Contacts_And_Orgs_Settings__c";

export default class StgPanelPayments extends LightningElement {
    _isAdmin = false;
    _isEditMode = false;
    _isSaving = false;
    _settings;
    @track _workingCopy = {};
    _oppRecordTypes = [];
    _oppTypes = [];
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavDonations,
        pageLabel: stgNavPayments,
        helpPaymentsEnabled: stgHelpPaymentsEnabled,
        helpMaxPayments: stgHelpMaxPayments,
        helpExcludedRecTypes: stgHelpOppRecTypesNoPayments,
        helpExcludedTypes: stgHelpOppTypesNoPayments,
        edit: stgBtnEdit,
        save: stgBtnSave,
        cancel: stgBtnCancel,
        none: stgLabelNone,
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

    get canEdit() {
        return this._isAdmin && !this._isEditMode;
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get paymentsEnabledDisplay() {
        return this._settings?.Payments_Enabled__c ? "Enabled" : "Disabled";
    }

    get maxPaymentsDisplay() {
        const val = this._settings?.Max_Payments__c;
        return val !== null && val !== undefined ? String(val) : this.labels.none;
    }

    get excludedRecTypesDisplay() {
        return this._resolveMultiSelectDisplay(
            this._settings?.Opp_RecTypes_Excluded_for_Payments__c,
            this._oppRecordTypes
        );
    }

    get excludedOppTypesDisplay() {
        return this._resolveMultiSelectDisplay(this._settings?.Opp_Types_Excluded_for_Payments__c, this._oppTypes);
    }

    get selectedExcludedRecTypes() {
        return this._parseMultiSelect(this._workingCopy?.Opp_RecTypes_Excluded_for_Payments__c);
    }

    get selectedExcludedOppTypes() {
        return this._parseMultiSelect(this._workingCopy?.Opp_Types_Excluded_for_Payments__c);
    }

    _resolveMultiSelectDisplay(rawValue, options) {
        if (!rawValue) {
            return this.labels.none;
        }
        const ids = rawValue.split(";").filter(Boolean);
        if (!ids.length) {
            return this.labels.none;
        }
        const map = new Map(options.map((o) => [o.value, o.label]));
        return ids.map((id) => map.get(id) || id).join(", ");
    }

    _parseMultiSelect(rawValue) {
        if (!rawValue) {
            return [];
        }
        return rawValue.split(";").filter(Boolean);
    }

    handleEdit() {
        this._workingCopy = { ...this._settings };
        this._isEditMode = true;
    }

    handleCancel() {
        this._workingCopy = {};
        this._isEditMode = false;
    }

    handlePaymentsEnabledChange(event) {
        this._workingCopy.Payments_Enabled__c = event.detail.checked;
    }

    handleMaxPaymentsChange(event) {
        this._workingCopy.Max_Payments__c = event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleExcludedRecTypesChange(event) {
        this._workingCopy.Opp_RecTypes_Excluded_for_Payments__c = event.detail.value.join(";");
    }

    handleExcludedOppTypesChange(event) {
        this._workingCopy.Opp_Types_Excluded_for_Payments__c = event.detail.value.join(";");
    }

    async handleSave() {
        this._isSaving = true;
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Payments_Enabled__c: this._workingCopy.Payments_Enabled__c,
                    Max_Payments__c: this._workingCopy.Max_Payments__c,
                    Opp_RecTypes_Excluded_for_Payments__c:
                        this._workingCopy.Opp_RecTypes_Excluded_for_Payments__c || null,
                    Opp_Types_Excluded_for_Payments__c: this._workingCopy.Opp_Types_Excluded_for_Payments__c || null,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this._isEditMode = false;
            this._workingCopy = {};
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Payment settings saved.", variant: "success" })
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
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return "An unexpected error occurred.";
    }
}
