import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getRecordTypeOptions from "@salesforce/apex/NppatchSettingsController.getRecordTypeOptions";
import getPicklistOptions from "@salesforce/apex/NppatchSettingsController.getPicklistOptions";

import stgNavDonations from "@salesforce/label/c.stgNavDonations";
import stgNavContactRoles from "@salesforce/label/c.stgNavContactRoles";
import stgHelpOCR from "@salesforce/label/c.stgHelpOCR";
import stgLabelNone from "@salesforce/label/c.stgLabelNone";

const CON_SETTINGS_OBJECT = "Contacts_And_Orgs_Settings__c";
const HH_SETTINGS_OBJECT = "Households_Settings__c";

export default class StgPanelContactRoles extends LightningElement {
    _conSettings;
    _hhSettings;
    @track _workingCopyCon = {};
    @track _workingCopyHH = {};
    _ocrRoleOptions = [];
    _contactRecordTypes = [];
    _hasError = false;
    _errorMessage;
    _wiredConSettingsResult;
    _wiredHHSettingsResult;
    _showOppGuidance = false;
    _showHHGuidance = false;

    labels = {
        sectionLabel: stgNavDonations,
        pageLabel: stgNavContactRoles,
        helpOCR: stgHelpOCR,
        helpOrgRole:
            "The default Contact Role assigned to the organizational Contact when an Opportunity is attributed to an Organization Account.",
        helpHonoreeRole: "The Contact Role assigned to the Honoree Contact on tribute Opportunities.",
        helpNotifRole: "The Contact Role assigned to the Notification Recipient Contact on tribute Opportunities.",
        helpHHOCR:
            "When enabled, automatically creates Opportunity Contact Roles for all Household members on household-attributed Opportunities.",
        helpHHExcludedRT: "Contact Record Types excluded from automatic Household Opportunity Contact Role creation.",
        none: stgLabelNone,
        defaultRole: "Default Contact Role",
        orgRole: "Organizational Contact Role",
        honoreeRole: "Honoree Contact Role",
        notifRole: "Notification Recipient Role",
        hhRolesOn: "Household Contact Roles",
        hhMemberRole: "Household Member Role",
        hhExcludedRT: "Excluded Record Types",
    };

    get oppGuidanceIcon() {
        return this._showOppGuidance ? "utility:chevrondown" : "utility:chevronright";
    }

    get hhGuidanceIcon() {
        return this._showHHGuidance ? "utility:chevrondown" : "utility:chevronright";
    }

    toggleOppGuidance() {
        this._showOppGuidance = !this._showOppGuidance;
    }

    toggleHHGuidance() {
        this._showHHGuidance = !this._showHHGuidance;
    }

    get sectionDescription() {
        return "Contact Roles define how Contacts are associated with Opportunities. These settings control which roles are automatically assigned during donation processing, household member management, and soft credit attribution.";
    }

    @wire(getSettings, { settingsObjectName: CON_SETTINGS_OBJECT })
    wiredConSettings(result) {
        this._wiredConSettingsResult = result;
        if (result.data) {
            this._conSettings = { ...result.data };
            this._hasError = false;
            this._tryPopulateWorkingCopies();
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    @wire(getSettings, { settingsObjectName: HH_SETTINGS_OBJECT })
    wiredHHSettings(result) {
        this._wiredHHSettingsResult = result;
        if (result.data) {
            this._hhSettings = { ...result.data };
            this._hasError = false;
            this._tryPopulateWorkingCopies();
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    @wire(getPicklistOptions, { sObjectApiName: "OpportunityContactRole", fieldApiName: "Role" })
    wiredOCRRoles({ data, error }) {
        if (data) {
            this._ocrRoleOptions = data.map((opt) => ({ label: opt.label, value: opt.value }));
        } else if (error) {
            this._ocrRoleOptions = [];
        }
    }

    @wire(getRecordTypeOptions, { sObjectApiName: "Contact" })
    wiredContactRecordTypes({ data, error }) {
        if (data) {
            this._contactRecordTypes = data.map((opt) => ({ label: opt.label, value: opt.value }));
        } else if (error) {
            this._contactRecordTypes = [];
        }
    }

    // --- Computed properties ---

    get isLoading() {
        return (!this._conSettings || !this._hhSettings) && !this._hasError;
    }

    get isReady() {
        return this._conSettings && this._hhSettings && !this._hasError;
    }

    get isHHRolesDisabled() {
        return !this._workingCopyHH?.Household_Contact_Roles_On__c;
    }

    get ocrRoleOptionsWithNone() {
        return [{ label: this.labels.none, value: "" }, ...this._ocrRoleOptions];
    }

    get selectedHHExcludedRT() {
        return this._parseMultiSelect(this._workingCopyHH?.Household_OCR_Excluded_Recordtypes__c);
    }

    // --- Utility ---

    _parseMultiSelect(rawValue) {
        if (!rawValue) {
            return [];
        }
        return rawValue.split(";").filter(Boolean);
    }

    // --- Working copy management ---

    _tryPopulateWorkingCopies() {
        if (this._conSettings && this._hhSettings) {
            this._workingCopyCon = { ...this._conSettings };
            this._workingCopyHH = { ...this._hhSettings };
        }
    }

    @api
    reset() {
        this._workingCopyCon = { ...this._conSettings };
        this._workingCopyHH = { ...this._hhSettings };
    }

    // --- Section 1 handlers (Contacts_And_Orgs_Settings__c) ---

    handleDefaultRoleChange(event) {
        this._workingCopyCon.Opportunity_Contact_Role_Default_role__c = event.detail.value || null;
    }

    handleOrgRoleChange(event) {
        this._workingCopyCon.Contact_Role_for_Organizational_Opps__c = event.detail.value || null;
    }

    handleHonoreeRoleChange(event) {
        this._workingCopyCon.Honoree_Opportunity_Contact_Role__c = event.detail.value || null;
    }

    handleNotifRoleChange(event) {
        this._workingCopyCon.Notification_Recipient_Opp_Contact_Role__c = event.detail.value || null;
    }

    // --- Section 2 handlers (Households_Settings__c) ---

    handleHHRolesOnChange(event) {
        this._workingCopyHH.Household_Contact_Roles_On__c = event.detail.checked;
    }

    handleHHMemberRoleChange(event) {
        this._workingCopyHH.Household_Member_Contact_Role__c = event.detail.value || null;
    }

    handleHHExcludedRTChange(event) {
        this._workingCopyHH.Household_OCR_Excluded_Recordtypes__c = event.detail.value.join(";");
    }

    // --- Save ---

    @api
    async save() {
        try {
            // Save Contacts_And_Orgs_Settings__c fields
            await saveSettings({
                settingsObjectName: CON_SETTINGS_OBJECT,
                fieldValues: {
                    Opportunity_Contact_Role_Default_role__c:
                        this._workingCopyCon.Opportunity_Contact_Role_Default_role__c || null,
                    Contact_Role_for_Organizational_Opps__c:
                        this._workingCopyCon.Contact_Role_for_Organizational_Opps__c || null,
                    Honoree_Opportunity_Contact_Role__c:
                        this._workingCopyCon.Honoree_Opportunity_Contact_Role__c || null,
                    Notification_Recipient_Opp_Contact_Role__c:
                        this._workingCopyCon.Notification_Recipient_Opp_Contact_Role__c || null,
                },
            });

            // Save Households_Settings__c fields
            await saveSettings({
                settingsObjectName: HH_SETTINGS_OBJECT,
                fieldValues: {
                    Household_Contact_Roles_On__c: this._workingCopyHH.Household_Contact_Roles_On__c,
                    Household_Member_Contact_Role__c: this._workingCopyHH.Household_Member_Contact_Role__c || null,
                    Household_OCR_Excluded_Recordtypes__c:
                        this._workingCopyHH.Household_OCR_Excluded_Recordtypes__c || null,
                },
            });

            await refreshApex(this._wiredConSettingsResult);
            await refreshApex(this._wiredHHSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Contact role settings saved.", variant: "success" })
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
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return "An unexpected error occurred.";
    }
}
