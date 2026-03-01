import { LightningElement, wire, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import stgNavPeople from "@salesforce/label/c.stgNavPeople";
import stgNavLeads from "@salesforce/label/c.stgNavLeads";
import stgHelpLeadConvert from "@salesforce/label/c.stgHelpLeadConvert";
import stgBtnEdit from "@salesforce/label/c.stgBtnEdit";
import stgBtnSave from "@salesforce/label/c.stgBtnSave";
import stgBtnCancel from "@salesforce/label/c.stgBtnCancel";

const SETTINGS_OBJECT = "Contacts_And_Orgs_Settings__c";

export default class StgPanelLeads extends LightningElement {
    @api isAdmin = false;
    _isEditMode = false;
    _isSaving = false;
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavPeople,
        pageLabel: stgNavLeads,
        helpLeadConvert: stgHelpLeadConvert,
        edit: stgBtnEdit,
        save: stgBtnSave,
        cancel: stgBtnCancel,
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
            this._hasError = false;
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    get canEdit() {
        return this.isAdmin && !this._isEditMode;
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get defaultOppOnConvertDisplay() {
        return this._settings?.Default_Opp_on_Convert__c ? "Checked" : "Unchecked";
    }

    get defaultOppOnConvertValue() {
        return this._workingCopy?.Default_Opp_on_Convert__c || false;
    }

    handleEdit() {
        this._workingCopy = { ...this._settings };
        this._isEditMode = true;
    }

    handleCancel() {
        this._workingCopy = {};
        this._isEditMode = false;
    }

    handleDefaultOppChange(event) {
        this._workingCopy.Default_Opp_on_Convert__c = event.detail.checked;
    }

    async handleSave() {
        this._isSaving = true;
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Default_Opp_on_Convert__c: this._workingCopy.Default_Opp_on_Convert__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this._isEditMode = false;
            this._workingCopy = {};
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Lead settings saved.", variant: "success" })
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
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return "An unexpected error occurred.";
    }
}
