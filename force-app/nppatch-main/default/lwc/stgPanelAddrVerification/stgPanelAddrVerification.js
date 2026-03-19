import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getAddressValidators from "@salesforce/apex/NppatchSettingsController.getAddressValidators";

import stgLabelNone from "@salesforce/label/c.stgLabelNone";

const SETTINGS_OBJECT = "Addr_Verification_Settings__c";
const OTHER_VALUE = "__other__";

export default class StgPanelAddrVerification extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;
    _validators = [];
    _validatorUrlMap = {};
    _comboSelection = null;

    labels = {
        verificationClass: "Verification Service",
        customClass: "Custom Verification Class",
        authToken: "Auth Token",
        endpoint: "Address Verification Endpoint",
        enableAutoVerification: "Enable Automatic Verification",
        rejectAmbiguous: "Reject Ambiguous Addresses",
        preventOverwrite: "Prevent Address Overwrite",
        timeout: "Timeout (seconds)",
        none: stgLabelNone,
    };

    get sectionDescription() {
        return "Address Verification uses an external service to validate and standardize mailing addresses on Contact and Account records. When enabled, addresses are verified as they are entered, helping ensure accurate data for mailings and reporting.";
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

    @wire(getAddressValidators)
    wiredValidators({ data, error }) {
        if (data) {
            this._validators = data;
            this._validatorUrlMap = {};
            data.forEach((v) => {
                this._validatorUrlMap[v.className] = v.defaultUrl;
            });
        } else if (error) {
            this._validators = [];
        }
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get isVerificationDisabled() {
        return !this._workingCopy?.Enable_Automatic_Verification__c;
    }

    get validatorOptions() {
        const opts = [{ label: this.labels.none, value: "" }];
        this._validators.forEach((v) => {
            opts.push({ label: v.serviceName, value: v.className });
        });
        opts.push({ label: "Other (custom class)", value: OTHER_VALUE });
        return opts;
    }

    get validatorComboValue() {
        if (this._comboSelection !== null) {
            return this._comboSelection;
        }
        const currentClass = this._workingCopy?.Class__c;
        if (!currentClass) {
            return "";
        }
        const known = this._validators.find((v) => v.className === currentClass);
        return known ? currentClass : OTHER_VALUE;
    }

    get isCustomClass() {
        return this.validatorComboValue === OTHER_VALUE;
    }

    handleValidatorChange(event) {
        const selected = event.detail.value;
        this._comboSelection = selected;
        if (selected === OTHER_VALUE) {
            this._workingCopy.Class__c = "";
            this._workingCopy.Address_Verification_Endpoint__c = "";
        } else if (selected === "") {
            this._workingCopy.Class__c = null;
            this._workingCopy.Address_Verification_Endpoint__c = null;
        } else {
            this._workingCopy.Class__c = selected;
            const defaultUrl = this._validatorUrlMap[selected];
            if (defaultUrl) {
                this._workingCopy.Address_Verification_Endpoint__c = defaultUrl;
            }
        }
    }

    handleCustomClassChange(event) {
        this._workingCopy.Class__c = event.detail.value;
    }

    handleAuthTokenChange(event) {
        this._workingCopy.Auth_Token__c = event.detail.value;
    }

    handleEndpointChange(event) {
        this._workingCopy.Address_Verification_Endpoint__c = event.detail.value;
    }

    handleEnableAutoChange(event) {
        this._workingCopy.Enable_Automatic_Verification__c = event.detail.checked;
    }

    handleRejectAmbiguousChange(event) {
        this._workingCopy.Reject_Ambiguous_Addresses__c = event.detail.checked;
    }

    handlePreventOverwriteChange(event) {
        this._workingCopy.Prevent_Address_Overwrite__c = event.detail.checked;
    }

    handleTimeoutChange(event) {
        this._workingCopy.Timeout__c = event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Class__c: this._workingCopy.Class__c || null,
                    Auth_Token__c: this._workingCopy.Auth_Token__c || null,
                    Address_Verification_Endpoint__c: this._workingCopy.Address_Verification_Endpoint__c || null,
                    Enable_Automatic_Verification__c: this._workingCopy.Enable_Automatic_Verification__c,
                    Reject_Ambiguous_Addresses__c: this._workingCopy.Reject_Ambiguous_Addresses__c,
                    Prevent_Address_Overwrite__c: this._workingCopy.Prevent_Address_Overwrite__c,
                    Timeout__c: this._workingCopy.Timeout__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Address verification settings saved.",
                    variant: "success",
                })
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
        this._comboSelection = null;
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
