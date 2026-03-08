import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";

export default class StgPanelSchedule extends LightningElement {
    _hasError = false;
    _errorMessage;

    _settingsCRLP;
    _settingsRD;
    _settingsLvl;
    _settingsHH;

    @track _workingCopyCRLP = {};
    @track _workingCopyRD = {};
    @track _workingCopyLvl = {};
    @track _workingCopyHH = {};

    _wiredCRLPResult;
    _wiredRDResult;
    _wiredLvlResult;
    _wiredHHResult;

    labels = {
        sectionLabel: "Bulk Data Processes",
        pageLabel: "Batch Process Settings",
        // Section subheaders
        batchSizesSection: "Rollup Batch Job Sizes",
        skewModeSection: "Skew Mode Batch Sizes",
        optionsSection: "Batch Processing Options",
        // Field labels + help text
        contactBatchSize: "Contact Hard Credit Batch Size",
        helpContactBatchSize: "Number of records per batch when calculating Contact hard credit rollups.",
        accountBatchSize: "Account Hard Credit Batch Size",
        helpAccountBatchSize: "Number of records per batch when calculating Account hard credit rollups.",
        contactSoftCreditBatchSize: "Contact Soft Credit Batch Size",
        helpContactSoftCreditBatchSize: "Number of records per batch when calculating Contact soft credit rollups.",
        acctContactSoftCreditBatchSize: "Account-Contact Soft Credit Batch Size",
        helpAcctContactSoftCreditBatchSize: "Number of records per batch when calculating Account-level Contact soft credit rollups.",
        accountSoftCreditBatchSize: "Account Soft Credit Batch Size",
        helpAccountSoftCreditBatchSize: "Number of records per batch when calculating Account soft credit rollups.",
        gauBatchSize: "GAU Batch Size",
        helpGauBatchSize: "Number of records per batch when calculating General Accounting Unit rollups.",
        rdBatchSize: "Recurring Donation Batch Size",
        helpRdBatchSize: "Number of records per batch when processing Recurring Donations. Reduce if the batch job fails due to governor limits.",
        levelBatchSize: "Level Assignment Batch Size",
        helpLevelBatchSize: "Number of records per batch when recalculating Level assignments.",
        seasonalAddressBatchSize: "Seasonal Addresses Batch Size",
        helpSeasonalAddressBatchSize: "Number of records per batch when updating seasonal addresses.",
        skewThreshold: "Skew Mode Threshold",
        helpSkewThreshold: "The maximum number of related Opportunities on an Account or Contact allowed in standard rollup batch jobs. Records exceeding this threshold are rolled up using Skew Mode instead.",
        contactSkewBatchSize: "Contact Skew Mode Batch Size",
        helpContactSkewBatchSize: "Number of records per batch when calculating Contact rollups in Skew Mode.",
        accountSkewBatchSize: "Account Skew Mode Batch Size",
        helpAccountSkewBatchSize: "Number of records per batch when calculating Account rollups in Skew Mode.",
        skewDispatcherBatchSize: "Skew Dispatcher Batch Size",
        helpSkewDispatcherBatchSize: "Controls the dispatcher batch size for Skew Mode processing.",
        useDatedConversionRates: "Use Dated Conversion Rates",
        helpUseDatedConversionRates: "Only applies to orgs with Advanced Currency Management (multi-currency) enabled. When on, rollup calculations use the exchange rate that was effective on each Opportunity's Close Date rather than the current default rate. Has no effect in single-currency orgs.",
    };

    get sectionDescription() {
        return "Batch processes run scheduled Apex jobs to calculate rollup summaries, update recurring donations, refresh seasonal addresses, and assign levels. These settings control the batch size \u2014 the number of records processed in each chunk. Larger batch sizes process faster but may hit governor limits. Reduce the batch size if jobs are failing.";
    }

    @wire(getSettings, { settingsObjectName: "Customizable_Rollup_Settings__c" })
    wiredCRLP(result) {
        this._wiredCRLPResult = result;
        if (result.data) {
            this._settingsCRLP = { ...result.data };
            this._hasError = false;
            this._tryPopulateWorkingCopies();
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    @wire(getSettings, { settingsObjectName: "Recurring_Donations_Settings__c" })
    wiredRD(result) {
        this._wiredRDResult = result;
        if (result.data) {
            this._settingsRD = { ...result.data };
            this._tryPopulateWorkingCopies();
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    @wire(getSettings, { settingsObjectName: "Levels_Settings__c" })
    wiredLvl(result) {
        this._wiredLvlResult = result;
        if (result.data) {
            this._settingsLvl = { ...result.data };
            this._tryPopulateWorkingCopies();
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    @wire(getSettings, { settingsObjectName: "Households_Settings__c" })
    wiredHH(result) {
        this._wiredHHResult = result;
        if (result.data) {
            this._settingsHH = { ...result.data };
            this._tryPopulateWorkingCopies();
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    get isLoading() {
        return (!this._settingsCRLP || !this._settingsRD || !this._settingsLvl || !this._settingsHH) && !this._hasError;
    }

    get isReady() {
        return this._settingsCRLP && this._settingsRD && this._settingsLvl && this._settingsHH && !this._hasError;
    }

    // --- Working copy management ---

    _tryPopulateWorkingCopies() {
        if (this._settingsCRLP && this._settingsRD && this._settingsLvl && this._settingsHH) {
            this._workingCopyCRLP = { ...this._settingsCRLP };
            this._workingCopyRD = { ...this._settingsRD };
            this._workingCopyLvl = { ...this._settingsLvl };
            this._workingCopyHH = { ...this._settingsHH };
        }
    }

    @api
    reset() {
        this._workingCopyCRLP = { ...this._settingsCRLP };
        this._workingCopyRD = { ...this._settingsRD };
        this._workingCopyLvl = { ...this._settingsLvl };
        this._workingCopyHH = { ...this._settingsHH };
    }

    // --- Individual change handlers (CRLP fields) ---

    handleContactBatchSizeChange(event) {
        this._workingCopyCRLP.Rollups_Contact_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleAccountBatchSizeChange(event) {
        this._workingCopyCRLP.Rollups_Account_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleContactSoftCreditBatchSizeChange(event) {
        this._workingCopyCRLP.Rollups_Contact_Soft_Credit_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleAcctContactSoftCreditBatchSizeChange(event) {
        this._workingCopyCRLP.Rollups_AcctContactSoftCredit_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleAccountSoftCreditBatchSizeChange(event) {
        this._workingCopyCRLP.Rollups_Account_Soft_Credit_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleGauBatchSizeChange(event) {
        this._workingCopyCRLP.Rollups_GAU_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    // --- Individual change handlers (Skew Mode - CRLP fields) ---

    handleSkewThresholdChange(event) {
        this._workingCopyCRLP.Rollups_Limit_on_Attached_Opps_for_Skew__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleContactSkewBatchSizeChange(event) {
        this._workingCopyCRLP.Rollups_Contact_SkewMode_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleAccountSkewBatchSizeChange(event) {
        this._workingCopyCRLP.Rollups_Account_SkewMode_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleSkewDispatcherBatchSizeChange(event) {
        this._workingCopyCRLP.Rollups_Skew_Dispatcher_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    // --- Individual change handlers (other settings objects) ---

    handleRdBatchSizeChange(event) {
        this._workingCopyRD.Recurring_Donation_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleLevelBatchSizeChange(event) {
        this._workingCopyLvl.Level_Assignment_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleSeasonalAddressBatchSizeChange(event) {
        this._workingCopyHH.Seasonal_Addresses_Batch_Size__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleUseDatedConversionRatesChange(event) {
        this._workingCopyHH.Use_Dated_Conversion_Rates__c = event.detail.checked;
    }

    // --- Save ---

    @api
    async save() {
        try {
            // Save Customizable_Rollup_Settings__c
            await saveSettings({
                settingsObjectName: "Customizable_Rollup_Settings__c",
                fieldValues: {
                    Rollups_Contact_Batch_Size__c: this._workingCopyCRLP.Rollups_Contact_Batch_Size__c,
                    Rollups_Account_Batch_Size__c: this._workingCopyCRLP.Rollups_Account_Batch_Size__c,
                    Rollups_Contact_Soft_Credit_Batch_Size__c: this._workingCopyCRLP.Rollups_Contact_Soft_Credit_Batch_Size__c,
                    Rollups_AcctContactSoftCredit_Batch_Size__c: this._workingCopyCRLP.Rollups_AcctContactSoftCredit_Batch_Size__c,
                    Rollups_Account_Soft_Credit_Batch_Size__c: this._workingCopyCRLP.Rollups_Account_Soft_Credit_Batch_Size__c,
                    Rollups_GAU_Batch_Size__c: this._workingCopyCRLP.Rollups_GAU_Batch_Size__c,
                    Rollups_Limit_on_Attached_Opps_for_Skew__c: this._workingCopyCRLP.Rollups_Limit_on_Attached_Opps_for_Skew__c,
                    Rollups_Contact_SkewMode_Batch_Size__c: this._workingCopyCRLP.Rollups_Contact_SkewMode_Batch_Size__c,
                    Rollups_Account_SkewMode_Batch_Size__c: this._workingCopyCRLP.Rollups_Account_SkewMode_Batch_Size__c,
                    Rollups_Skew_Dispatcher_Batch_Size__c: this._workingCopyCRLP.Rollups_Skew_Dispatcher_Batch_Size__c,
                },
            });

            // Save Recurring_Donations_Settings__c
            await saveSettings({
                settingsObjectName: "Recurring_Donations_Settings__c",
                fieldValues: {
                    Recurring_Donation_Batch_Size__c: this._workingCopyRD.Recurring_Donation_Batch_Size__c,
                },
            });

            // Save Levels_Settings__c
            await saveSettings({
                settingsObjectName: "Levels_Settings__c",
                fieldValues: {
                    Level_Assignment_Batch_Size__c: this._workingCopyLvl.Level_Assignment_Batch_Size__c,
                },
            });

            // Save Households_Settings__c
            await saveSettings({
                settingsObjectName: "Households_Settings__c",
                fieldValues: {
                    Seasonal_Addresses_Batch_Size__c: this._workingCopyHH.Seasonal_Addresses_Batch_Size__c,
                    Use_Dated_Conversion_Rates__c: this._workingCopyHH.Use_Dated_Conversion_Rates__c,
                },
            });

            // Refresh all wires
            await Promise.all([
                refreshApex(this._wiredCRLPResult),
                refreshApex(this._wiredRDResult),
                refreshApex(this._wiredLvlResult),
                refreshApex(this._wiredHHResult),
            ]);

            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Batch settings saved.", variant: "success" })
            );
            return true;
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({ title: "Error", message: this._extractError(error), variant: "error" })
            );
            return false;
        }
    }

    _extractError(error) {
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return "An unexpected error occurred.";
    }
}
