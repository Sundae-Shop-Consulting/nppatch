import { LightningElement, wire, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import stgNavRelationships from "@salesforce/label/c.stgNavRelationships";
import stgNavAffiliations from "@salesforce/label/c.stgNavAffiliations";
import stgHelpAutoAffil from "@salesforce/label/c.stgHelpAutoAffil";
import stgBtnEdit from "@salesforce/label/c.stgBtnEdit";
import stgBtnSave from "@salesforce/label/c.stgBtnSave";
import stgBtnCancel from "@salesforce/label/c.stgBtnCancel";

const SETTINGS_OBJECT = "Affiliations_Settings__c";

export default class StgPanelAffiliations extends LightningElement {
    @api isAdmin = false;
    _isEditMode = false;
    _isSaving = false;
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        sectionLabel: stgNavRelationships,
        pageLabel: stgNavAffiliations,
        helpAutoAffil: stgHelpAutoAffil,
        edit: stgBtnEdit,
        save: stgBtnSave,
        cancel: stgBtnCancel,
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

    get autoAffilDisplay() {
        return this._settings?.Automatic_Affiliation_Creation_Turned_On__c ? "Enabled" : "Disabled";
    }

    get autoAffilValue() {
        return this._workingCopy?.Automatic_Affiliation_Creation_Turned_On__c || false;
    }

    handleEdit() {
        this._workingCopy = { ...this._settings };
        this._isEditMode = true;
    }

    handleCancel() {
        this._workingCopy = {};
        this._isEditMode = false;
    }

    handleAutoAffilChange(event) {
        this._workingCopy.Automatic_Affiliation_Creation_Turned_On__c = event.detail.checked;
    }

    async handleSave() {
        this._isSaving = true;
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Automatic_Affiliation_Creation_Turned_On__c:
                        this._workingCopy.Automatic_Affiliation_Creation_Turned_On__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this._isEditMode = false;
            this._workingCopy = {};
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Affiliation settings saved.", variant: "success" })
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
