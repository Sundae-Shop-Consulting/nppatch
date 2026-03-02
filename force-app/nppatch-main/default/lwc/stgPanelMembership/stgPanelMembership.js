import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getRecordTypeOptions from "@salesforce/apex/NppatchSettingsController.getRecordTypeOptions";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

import stgNavDonations from "@salesforce/label/c.stgNavDonations";
import stgNavMembership from "@salesforce/label/c.stgNavMembership";
import stgHelpMembershipRT from "@salesforce/label/c.stgHelpMembershipRT";
import stgHelpMembershipGracePeriod from "@salesforce/label/c.stgHelpMembershipGracePeriod";
import stgBtnEdit from "@salesforce/label/c.stgBtnEdit";
import stgBtnSave from "@salesforce/label/c.stgBtnSave";
import stgBtnCancel from "@salesforce/label/c.stgBtnCancel";
import stgLabelNone from "@salesforce/label/c.stgLabelNone";

export default class StgPanelMembership extends LightningElement {
    _isAdmin = false;
    _isEditMode = false;
    _isSaving = false;
    _settings;
    @track _workingCopy = {};
    _recordTypeOptions = [];
    _crlpEnabled = false;
    _hasError = false;
    _errorMessage;

    _wiredHouseholdsResult;
    _wiredCrlpResult;

    labels = {
        sectionLabel: stgNavDonations,
        pageLabel: stgNavMembership,
        helpMembershipRT: stgHelpMembershipRT,
        helpGracePeriod: stgHelpMembershipGracePeriod,
        edit: stgBtnEdit,
        save: stgBtnSave,
        cancel: stgBtnCancel,
        none: stgLabelNone,
        membershipRecordTypes: "Membership Record Types",
        gracePeriod: "Membership Grace Period",
    };

    @wire(getSettings, { settingsObjectName: "Households_Settings__c" })
    wiredHouseholdsSettings(result) {
        this._wiredHouseholdsResult = result;
        if (result.data) {
            this._settings = { ...result.data };
            this._hasError = false;
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    @wire(getSettings, { settingsObjectName: "Customizable_Rollup_Settings__c" })
    wiredCrlpSettings(result) {
        this._wiredCrlpResult = result;
        if (result.data) {
            this._crlpEnabled = !!result.data.Customizable_Rollups_Enabled__c;
        }
    }

    @wire(isAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this._isAdmin = data;
        }
    }

    @wire(getRecordTypeOptions, { sObjectApiName: "Opportunity" })
    wiredRecordTypeOptions({ data, error }) {
        if (data) {
            this._recordTypeOptions = data.map((opt) => ({
                label: opt.label,
                value: opt.value,
            }));
        } else if (error) {
            this._recordTypeOptions = [];
        }
    }

    // --- Computed properties ---

    get canEdit() {
        return this._isAdmin && !this._isEditMode;
    }

    get sectionDescription() {
        if (this._crlpEnabled) {
            return "Memberships track recurring organizational relationships such as annual dues or subscriptions. The grace period defines how many days past expiration a membership is still considered current for reporting purposes.";
        }
        return "Memberships track recurring organizational relationships such as annual dues or subscriptions. Select which Opportunity record types represent memberships, and set the grace period that defines how many days past expiration a membership is still considered current.";
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get showRecordTypeField() {
        return !this._crlpEnabled;
    }

    get membershipRecordTypeDisplay() {
        if (!this._settings?.Membership_Record_Types__c || !this._recordTypeOptions.length) {
            return this.labels.none;
        }
        const selectedIds = this._settings.Membership_Record_Types__c.split(";").filter(Boolean);
        if (!selectedIds.length) {
            return this.labels.none;
        }
        const optionsMap = new Map(
            this._recordTypeOptions.map((opt) => [opt.value, opt.label])
        );
        const names = selectedIds.map((id) => optionsMap.get(id) || id);
        return names.join(", ");
    }

    get gracePeriodDisplay() {
        const val = this._settings?.Membership_Grace_Period__c;
        return val !== null && val !== undefined ? String(val) : this.labels.none;
    }

    // --- Edit-mode values ---

    get selectedRecordTypes() {
        const raw = this._workingCopy?.Membership_Record_Types__c;
        if (!raw) {return [];}
        return raw.split(";").filter(Boolean);
    }

    get gracePeriodValue() {
        return this._workingCopy?.Membership_Grace_Period__c;
    }

    // --- Actions ---

    handleEdit() {
        this._workingCopy = { ...this._settings };
        this._isEditMode = true;
    }

    handleCancel() {
        this._workingCopy = {};
        this._isEditMode = false;
    }

    handleRecordTypeChange(event) {
        this._workingCopy.Membership_Record_Types__c =
            event.detail.value.join(";");
    }

    handleGracePeriodChange(event) {
        this._workingCopy.Membership_Grace_Period__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    async handleSave() {
        this._isSaving = true;
        try {
            const fieldValues = {
                Membership_Record_Types__c:
                    this._workingCopy.Membership_Record_Types__c || null,
                Membership_Grace_Period__c:
                    this._workingCopy.Membership_Grace_Period__c,
            };
            await saveSettings({
                settingsObjectName: "Households_Settings__c",
                fieldValues,
            });
            await refreshApex(this._wiredHouseholdsResult);
            this._isEditMode = false;
            this._workingCopy = {};
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Membership settings saved.",
                    variant: "success",
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: this._extractError(error),
                    variant: "error",
                })
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
