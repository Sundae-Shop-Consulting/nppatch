import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getRecordTypeOptions from "@salesforce/apex/NppatchSettingsController.getRecordTypeOptions";
import getPicklistOptions from "@salesforce/apex/NppatchSettingsController.getPicklistOptions";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

import stgNavDonations from "@salesforce/label/c.stgNavDonations";
import stgNavContactRoles from "@salesforce/label/c.stgNavContactRoles";
import stgHelpOCR from "@salesforce/label/c.stgHelpOCR";
import stgHelpSoftCreditRoles from "@salesforce/label/c.stgHelpSoftCreditRoles";
import stgHelpMatchedDonorRole from "@salesforce/label/c.stgHelpMatchedDonorRole";
import stgBtnEdit from "@salesforce/label/c.stgBtnEdit";
import stgBtnSave from "@salesforce/label/c.stgBtnSave";
import stgBtnCancel from "@salesforce/label/c.stgBtnCancel";
import stgLabelNone from "@salesforce/label/c.stgLabelNone";

const CON_SETTINGS_OBJECT = "Contacts_And_Orgs_Settings__c";
const HH_SETTINGS_OBJECT = "Households_Settings__c";

export default class StgPanelContactRoles extends LightningElement {
    _isAdmin = false;
    _isEditMode = false;
    _isSaving = false;
    _conSettings;
    _hhSettings;
    @track _workingCopyCon = {};
    @track _workingCopyHH = {};
    _crlpEnabled = false;
    _ocrRoleOptions = [];
    _contactRecordTypes = [];
    _hasError = false;
    _errorMessage;
    _wiredConSettingsResult;
    _wiredHHSettingsResult;

    labels = {
        sectionLabel: stgNavDonations,
        pageLabel: stgNavContactRoles,
        helpOCR: stgHelpOCR,
        helpOrgRole: "The default Contact Role assigned to the organizational Contact when an Opportunity is attributed to an Organization Account.",
        helpHonoreeRole: "The Contact Role assigned to the Honoree Contact on tribute Opportunities.",
        helpNotifRole: "The Contact Role assigned to the Notification Recipient Contact on tribute Opportunities.",
        helpHHOCR: "When enabled, automatically creates Opportunity Contact Roles for all Household members on household-attributed Opportunities.",
        helpHHExcludedRT: "Contact Record Types excluded from automatic Household Opportunity Contact Role creation.",
        helpSoftCreditRollups: "When enabled, rollup fields on Contacts include soft credit Opportunities based on their Contact Roles.",
        helpSoftCreditRoles: stgHelpSoftCreditRoles,
        helpMatchedDonorRole: stgHelpMatchedDonorRole,
        helpAlwaysRollupPrimary: "When enabled, the primary Contact on an Opportunity always receives hard credit rollups, even when the Opportunity is attributed to an Organization Account.",
        edit: stgBtnEdit,
        save: stgBtnSave,
        cancel: stgBtnCancel,
        none: stgLabelNone,
        defaultRole: "Default Contact Role",
        orgRole: "Organizational Contact Role",
        honoreeRole: "Honoree Contact Role",
        notifRole: "Notification Recipient Role",
        hhRolesOn: "Household Contact Roles",
        hhMemberRole: "Household Member Role",
        hhExcludedRT: "Excluded Record Types",
        alwaysRollupPrimary: "Always Rollup to Primary Contact",
        enableSoftCredit: "Enable Soft Credit Rollups",
        softCreditRoles: "Soft Credit Roles",
        matchedDonorRole: "Matched Donor Role",
    };

    get sectionDescription() {
        return "Contact Roles define how Contacts are associated with Opportunities. These settings control which roles are automatically assigned during donation processing, household member management, and soft credit attribution.";
    }

    @wire(getSettings, { settingsObjectName: CON_SETTINGS_OBJECT })
    wiredConSettings(result) {
        this._wiredConSettingsResult = result;
        if (result.data) {
            this._conSettings = { ...result.data };
            this._hasError = false;
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

    get canEdit() {
        return this._isAdmin && !this._isEditMode;
    }

    get isLoading() {
        return (!this._conSettings || !this._hhSettings) && !this._hasError;
    }

    get isReady() {
        return this._conSettings && this._hhSettings;
    }

    get showSoftCreditSection() {
        return !this._crlpEnabled;
    }

    get ocrRoleOptionsWithNone() {
        return [{ label: this.labels.none, value: "" }, ...this._ocrRoleOptions];
    }

    // --- Section 1: Opportunity Contact Roles (from Contacts_And_Orgs_Settings__c) ---

    get defaultRoleDisplay() {
        return this._conSettings?.Opportunity_Contact_Role_Default_role__c || this.labels.none;
    }

    get orgRoleDisplay() {
        return this._conSettings?.Contact_Role_for_Organizational_Opps__c || this.labels.none;
    }

    get honoreeRoleDisplay() {
        return this._conSettings?.Honoree_Opportunity_Contact_Role__c || this.labels.none;
    }

    get notifRoleDisplay() {
        return this._conSettings?.Notification_Recipient_Opp_Contact_Role__c || this.labels.none;
    }

    // --- Section 2: Household Contact Roles (from Households_Settings__c) ---

    get hhRolesOnDisplay() {
        return this._hhSettings?.Household_Contact_Roles_On__c ? "Enabled" : "Disabled";
    }

    get hhMemberRoleDisplay() {
        return this._hhSettings?.Household_Member_Contact_Role__c || this.labels.none;
    }

    get hhExcludedRTDisplay() {
        return this._resolveMultiSelectDisplay(
            this._hhSettings?.Household_OCR_Excluded_Recordtypes__c,
            this._contactRecordTypes
        );
    }

    get selectedHHExcludedRT() {
        return this._parseMultiSelect(this._workingCopyHH?.Household_OCR_Excluded_Recordtypes__c);
    }

    // --- Section 3: Soft Credit (from Households_Settings__c, only when CRLP disabled) ---

    get alwaysRollupPrimaryDisplay() {
        return this._hhSettings?.Always_Rollup_to_Primary_Contact__c ? "Enabled" : "Disabled";
    }

    get enableSoftCreditDisplay() {
        return this._hhSettings?.Enable_Soft_Credit_Rollups__c ? "Enabled" : "Disabled";
    }

    get softCreditRolesDisplay() {
        return this._resolveMultiSelectDisplay(
            this._hhSettings?.Soft_Credit_Roles__c,
            this._ocrRoleOptions
        );
    }

    get selectedSoftCreditRoles() {
        return this._parseMultiSelect(this._workingCopyHH?.Soft_Credit_Roles__c);
    }

    get matchedDonorRoleDisplay() {
        return this._hhSettings?.Matched_Donor_Role__c || this.labels.none;
    }

    // --- Utility ---

    _resolveMultiSelectDisplay(rawValue, options) {
        if (!rawValue) return this.labels.none;
        const ids = rawValue.split(";").filter(Boolean);
        if (!ids.length) return this.labels.none;
        const map = new Map(options.map((o) => [o.value, o.label]));
        return ids.map((id) => map.get(id) || id).join(", ");
    }

    _parseMultiSelect(rawValue) {
        if (!rawValue) return [];
        return rawValue.split(";").filter(Boolean);
    }

    // --- Actions ---

    handleEdit() {
        this._workingCopyCon = { ...this._conSettings };
        this._workingCopyHH = { ...this._hhSettings };
        this._isEditMode = true;
    }

    handleCancel() {
        this._workingCopyCon = {};
        this._workingCopyHH = {};
        this._isEditMode = false;
    }

    // Section 1 handlers (Contacts_And_Orgs_Settings__c)
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

    // Section 2 handlers (Households_Settings__c)
    handleHHRolesOnChange(event) {
        this._workingCopyHH.Household_Contact_Roles_On__c = event.detail.checked;
    }

    handleHHMemberRoleChange(event) {
        this._workingCopyHH.Household_Member_Contact_Role__c = event.detail.value || null;
    }

    handleHHExcludedRTChange(event) {
        this._workingCopyHH.Household_OCR_Excluded_Recordtypes__c = event.detail.value.join(";");
    }

    // Section 3 handlers (Households_Settings__c)
    handleAlwaysRollupPrimaryChange(event) {
        this._workingCopyHH.Always_Rollup_to_Primary_Contact__c = event.detail.checked;
    }

    handleEnableSoftCreditChange(event) {
        this._workingCopyHH.Enable_Soft_Credit_Rollups__c = event.detail.checked;
    }

    handleSoftCreditRolesChange(event) {
        this._workingCopyHH.Soft_Credit_Roles__c = event.detail.value.join(";");
    }

    handleMatchedDonorRoleChange(event) {
        this._workingCopyHH.Matched_Donor_Role__c = event.detail.value || null;
    }

    async handleSave() {
        this._isSaving = true;
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
            const hhFieldValues = {
                Household_Contact_Roles_On__c:
                    this._workingCopyHH.Household_Contact_Roles_On__c,
                Household_Member_Contact_Role__c:
                    this._workingCopyHH.Household_Member_Contact_Role__c || null,
                Household_OCR_Excluded_Recordtypes__c:
                    this._workingCopyHH.Household_OCR_Excluded_Recordtypes__c || null,
                Always_Rollup_to_Primary_Contact__c:
                    this._workingCopyHH.Always_Rollup_to_Primary_Contact__c,
                Enable_Soft_Credit_Rollups__c:
                    this._workingCopyHH.Enable_Soft_Credit_Rollups__c,
                Soft_Credit_Roles__c:
                    this._workingCopyHH.Soft_Credit_Roles__c || null,
                Matched_Donor_Role__c:
                    this._workingCopyHH.Matched_Donor_Role__c || null,
            };
            await saveSettings({
                settingsObjectName: HH_SETTINGS_OBJECT,
                fieldValues: hhFieldValues,
            });

            await refreshApex(this._wiredConSettingsResult);
            await refreshApex(this._wiredHHSettingsResult);
            this._isEditMode = false;
            this._workingCopyCon = {};
            this._workingCopyHH = {};
            this.dispatchEvent(
                new ShowToastEvent({ title: "Success", message: "Contact role settings saved.", variant: "success" })
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
