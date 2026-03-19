import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";

import stgHelpRollupNDayValue from "@salesforce/label/c.stgHelpRollupNDayValue";
import stgHelpFiscalYearRollups from "@salesforce/label/c.stgHelpFiscalYearRollups";

const SETTINGS_OBJECT = "Households_Settings__c";

export default class StgPanelDonorStatistics extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    labels = {
        helpNDayValue: stgHelpRollupNDayValue,
        helpFiscalYear: stgHelpFiscalYearRollups,
        nDayValue: "N-Day Rollup Value",
        fiscalYear: "Use Fiscal Year for Rollups",
    };

    get sectionDescription() {
        return "Donor statistics summarize each Contact\u2019s and Account\u2019s giving history \u2014 including total lifetime donations, largest gift, and recent giving trends. The N-day value sets the rolling window (for example, last 365 days) used for recent giving calculations.";
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

    handleNDayChange(event) {
        this._workingCopy.Rollup_N_Day_Value__c = event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleFiscalYearChange(event) {
        this._workingCopy.Use_Fiscal_Year_for_Rollups__c = event.detail.checked;
    }

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Rollup_N_Day_Value__c: this._workingCopy.Rollup_N_Day_Value__c,
                    Use_Fiscal_Year_for_Rollups__c: this._workingCopy.Use_Fiscal_Year_for_Rollups__c,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Donor statistics settings saved.",
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
