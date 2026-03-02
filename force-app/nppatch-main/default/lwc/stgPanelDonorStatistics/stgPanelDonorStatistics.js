import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getRecordTypeOptions from "@salesforce/apex/NppatchSettingsController.getRecordTypeOptions";
import getPicklistOptions from "@salesforce/apex/NppatchSettingsController.getPicklistOptions";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

import stgNavDonations from "@salesforce/label/c.stgNavDonations";
import stgNavDonorStatistics from "@salesforce/label/c.stgNavDonorStatistics";
import stgHelpRollupNDayValue from "@salesforce/label/c.stgHelpRollupNDayValue";
import stgHelpFiscalYearRollups from "@salesforce/label/c.stgHelpFiscalYearRollups";
import stgHelpRollupExcludeAccountOppRT from "@salesforce/label/c.stgHelpRollupExcludeAccountOppRT";
import stgHelpRollupExcludeAccountOppType from "@salesforce/label/c.stgHelpRollupExcludeAccountOppType";
import stgHelpRollupExcludeContactOppRT from "@salesforce/label/c.stgHelpRollupExcludeContactOppRT";
import stgHelpRollupExcludeContactOppType from "@salesforce/label/c.stgHelpRollupExcludeContactOppType";
import stgBtnEdit from "@salesforce/label/c.stgBtnEdit";
import stgBtnSave from "@salesforce/label/c.stgBtnSave";
import stgBtnCancel from "@salesforce/label/c.stgBtnCancel";
import stgLabelNone from "@salesforce/label/c.stgLabelNone";

const SETTINGS_OBJECT = "Households_Settings__c";

export default class StgPanelDonorStatistics extends LightningElement {
    _isAdmin = false;
    _isEditMode = false;
    _isSaving = false;
    _settings;
    @track _workingCopy = {};
    _crlpEnabled = false;
    _oppRecordTypes = [];
    _oppTypes = [];
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavDonations,
        pageLabel: stgNavDonorStatistics,
        helpNDayValue: stgHelpRollupNDayValue,
        helpFiscalYear: stgHelpFiscalYearRollups,
        helpExclAcctRT: stgHelpRollupExcludeAccountOppRT,
        helpExclAcctType: stgHelpRollupExcludeAccountOppType,
        helpExclConRT: stgHelpRollupExcludeContactOppRT,
        helpExclConType: stgHelpRollupExcludeContactOppType,
        edit: stgBtnEdit,
        save: stgBtnSave,
        cancel: stgBtnCancel,
        none: stgLabelNone,
        nDayValue: "N-Day Rollup Value",
        fiscalYear: "Use Fiscal Year for Rollups",
        exclAcctOppRT: "Excluded Account Opp Record Types",
        exclAcctOppType: "Excluded Account Opp Types",
        exclConOppRT: "Excluded Contact Opp Record Types",
        exclConOppType: "Excluded Contact Opp Types",
    };

    get sectionDescription() {
        if (this._crlpEnabled) {
            return "Donor statistics summarize each Contact\u2019s and Account\u2019s giving history \u2014 including total lifetime donations, largest gift, and recent giving trends. The N-day value sets the rolling window (for example, last 365 days) used for recent giving calculations.";
        }
        return "Donor statistics summarize each Contact\u2019s and Account\u2019s giving history \u2014 including total lifetime donations, largest gift, and recent giving trends. These settings control the rollup window, fiscal year preference, and which Opportunity types to exclude from calculations.";
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

    @wire(getSettings, { settingsObjectName: "Customizable_Rollup_Settings__c" })
    wiredCrlpSettings({ data }) {
        if (data) {
            this._crlpEnabled = !!data.Customizable_Rollups_Enabled__c;
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

    get showExclusionFields() {
        return !this._crlpEnabled;
    }

    get nDayValueDisplay() {
        const val = this._settings?.Rollup_N_Day_Value__c;
        return val !== null && val !== undefined ? String(val) : this.labels.none;
    }

    get fiscalYearDisplay() {
        return this._settings?.Use_Fiscal_Year_for_Rollups__c ? "Enabled" : "Disabled";
    }

    get exclAcctOppRTDisplay() {
        return this._resolveMultiSelectDisplay(this._settings?.Excluded_Account_Opp_Rectypes__c, this._oppRecordTypes);
    }

    get exclAcctOppTypeDisplay() {
        return this._resolveMultiSelectDisplay(this._settings?.Excluded_Account_Opp_Types__c, this._oppTypes);
    }

    get exclConOppRTDisplay() {
        return this._resolveMultiSelectDisplay(this._settings?.Excluded_Contact_Opp_Rectypes__c, this._oppRecordTypes);
    }

    get exclConOppTypeDisplay() {
        return this._resolveMultiSelectDisplay(this._settings?.Excluded_Contact_Opp_Types__c, this._oppTypes);
    }

    get selectedExclAcctOppRT() {
        return this._parseMultiSelect(this._workingCopy?.Excluded_Account_Opp_Rectypes__c);
    }

    get selectedExclAcctOppType() {
        return this._parseMultiSelect(this._workingCopy?.Excluded_Account_Opp_Types__c);
    }

    get selectedExclConOppRT() {
        return this._parseMultiSelect(this._workingCopy?.Excluded_Contact_Opp_Rectypes__c);
    }

    get selectedExclConOppType() {
        return this._parseMultiSelect(this._workingCopy?.Excluded_Contact_Opp_Types__c);
    }

    _resolveMultiSelectDisplay(rawValue, options) {
        if (!rawValue) {return this.labels.none;}
        const ids = rawValue.split(";").filter(Boolean);
        if (!ids.length) {return this.labels.none;}
        const map = new Map(options.map((o) => [o.value, o.label]));
        return ids.map((id) => map.get(id) || id).join(", ");
    }

    _parseMultiSelect(rawValue) {
        if (!rawValue) {return [];}
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

    handleNDayChange(event) {
        this._workingCopy.Rollup_N_Day_Value__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleFiscalYearChange(event) {
        this._workingCopy.Use_Fiscal_Year_for_Rollups__c = event.detail.checked;
    }

    handleExclAcctRTChange(event) {
        this._workingCopy.Excluded_Account_Opp_Rectypes__c = event.detail.value.join(";");
    }

    handleExclAcctTypeChange(event) {
        this._workingCopy.Excluded_Account_Opp_Types__c = event.detail.value.join(";");
    }

    handleExclConRTChange(event) {
        this._workingCopy.Excluded_Contact_Opp_Rectypes__c = event.detail.value.join(";");
    }

    handleExclConTypeChange(event) {
        this._workingCopy.Excluded_Contact_Opp_Types__c = event.detail.value.join(";");
    }

    async handleSave() {
        this._isSaving = true;
        try {
            const fieldValues = {
                Rollup_N_Day_Value__c: this._workingCopy.Rollup_N_Day_Value__c,
                Use_Fiscal_Year_for_Rollups__c: this._workingCopy.Use_Fiscal_Year_for_Rollups__c,
            };
            if (!this._crlpEnabled) {
                fieldValues.Excluded_Account_Opp_Rectypes__c =
                    this._workingCopy.Excluded_Account_Opp_Rectypes__c || null;
                fieldValues.Excluded_Account_Opp_Types__c =
                    this._workingCopy.Excluded_Account_Opp_Types__c || null;
                fieldValues.Excluded_Contact_Opp_Rectypes__c =
                    this._workingCopy.Excluded_Contact_Opp_Rectypes__c || null;
                fieldValues.Excluded_Contact_Opp_Types__c =
                    this._workingCopy.Excluded_Contact_Opp_Types__c || null;
            }
            await saveSettings({ settingsObjectName: SETTINGS_OBJECT, fieldValues });
            await refreshApex(this._wiredSettingsResult);
            this._isEditMode = false;
            this._workingCopy = {};
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Donor statistics settings saved.", variant: "success" })
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
