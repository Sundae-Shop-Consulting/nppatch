import { LightningElement, wire } from "lwc";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

export default class StgPanelAddrVerification extends LightningElement {
    _settings;
    _hasError = false;
    _errorMessage = "";
    _canEdit = false;

    @wire(isAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {this._canEdit = data;}
    }

    @wire(getSettings, { settingsObjectName: "Contacts_And_Orgs_Settings__c" })
    wiredSettings(result) {
        if (result.data) {
            this._settings = result.data;
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = result.error?.body?.message || "Error loading settings.";
        }
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }
}
