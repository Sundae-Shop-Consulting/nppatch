import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getRecordTypeOptions from "@salesforce/apex/NppatchSettingsController.getRecordTypeOptions";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

const OTHER_VALUE = "Other";

const NAME_FORMAT_OPTIONS = [
    { label: "(None)", value: "" },
    { label: "{!LastName} Household", value: "{!LastName} Household" },
    { label: "{!{!FirstName}} {!LastName} Household", value: "{!{!FirstName}} {!LastName} Household" },
    { label: "{!LastName} ({!{!FirstName}}) Household", value: "{!LastName} ({!{!FirstName}}) Household" },
    { label: "{!LastName} Family", value: "{!LastName} Family" },
    { label: "{!{!FirstName}} {!LastName} Family", value: "{!{!FirstName}} {!LastName} Family" },
    { label: "{!LastName} ({!{!FirstName}}) Family", value: "{!LastName} ({!{!FirstName}}) Family" },
    { label: OTHER_VALUE, value: OTHER_VALUE },
];

const FORMAL_GREETING_OPTIONS = [
    { label: "(None)", value: "" },
    { label: "{!{!FirstName}} {!LastName}", value: "{!{!FirstName}} {!LastName}" },
    { label: "{!{!Salutation} {!FirstName}} {!LastName}", value: "{!{!Salutation} {!FirstName}} {!LastName}" },
    { label: "{!{!Salutation}} {!FirstName} {!LastName}", value: "{!{!Salutation}} {!FirstName} {!LastName}" },
    { label: OTHER_VALUE, value: OTHER_VALUE },
];

const INFORMAL_GREETING_OPTIONS = [
    { label: "(None)", value: "" },
    { label: "{!{!FirstName}}", value: "{!{!FirstName}}" },
    { label: "{!{!FirstName}} {!LastName}", value: "{!{!FirstName}} {!LastName}" },
    { label: OTHER_VALUE, value: OTHER_VALUE },
];

export default class StgPanelHouseholds extends LightningElement {
    _isAdmin = false;
    _isEditMode = false;
    _isSaving = false;
    _settingsNaming;
    _settingsHH;
    @track _workingCopyNaming = {};
    @track _workingCopyHH = {};
    _contactRecordTypeOptions = [];
    _hasError = false;
    _errorMessage;

    _wiredNamingResult;
    _wiredHHResult;

    // Track whether the user has explicitly selected "Other" in edit mode
    _nameFormatIsOther = false;
    _formalGreetingIsOther = false;
    _informalGreetingIsOther = false;

    labels = {
        sectionLabel: "People",
        pageLabel: "Households",
        edit: "Edit",
        save: "Save",
        cancel: "Cancel",
        sectionDescription:
            "Household naming automatically generates names and greetings for Household Accounts \u2014 such as \u2018The Smith Family\u2019 or \u2018John and Jane Smith.\u2019 These settings control the format templates, connectors, and overflow rules used to build those names. You can also define which Contacts receive Household records and link a mailing list report for Campaign deduplication.",
        // Section subheaders
        namingSection: "Household Naming",
        objectSection: "Household Object",
        generalSection: "General",
        // Field labels
        advancedNaming: "Advanced Household Naming",
        helpAdvancedNaming:
            "When enabled, the system automatically generates Household Names, Informal Greetings, and Formal Greetings based on the format templates below.",
        nameFormat: "Household Name Format",
        helpNameFormat:
            "The template used to generate the Household Account name. Use merge fields like {!LastName} and {!{!FirstName}} to build the format.",
        customNameFormat: "Custom Name Format",
        formalGreeting: "Formal Greeting Format",
        helpFormalGreeting:
            "The template used to generate the formal greeting, typically used in correspondence headers.",
        customFormalGreeting: "Custom Formal Greeting Format",
        informalGreeting: "Informal Greeting Format",
        helpInformalGreeting:
            "The template used to generate the informal greeting, typically used in casual correspondence.",
        customInformalGreeting: "Custom Informal Greeting Format",
        nameConnector: "Name Connector",
        helpNameConnector:
            "The string used to connect pairs of names \u2014 for example, '&' produces 'John & Jane.'",
        nameOverrun: "Name Overrun",
        helpNameOverrun:
            "The string used when the list of names exceeds the overrun count \u2014 for example, 'et al.' or 'Family.'",
        contactOverrunCount: "Contact Overrun Count",
        helpContactOverrunCount:
            "The number of Contacts to list explicitly before replacing the remainder with the Name Overrun string.",
        implementingClass: "Implementing Class",
        helpImplementingClass:
            "The fully qualified name of an Apex class implementing the HH_INaming interface for custom naming logic.",
        householdRules: "Household Object Rules",
        helpHouseholdRules:
            "Controls which Contacts automatically receive a Household object. This setting only applies when using the One-to-One or Individual Account model \u2014 it is ignored for the Household Account model.",
        excludedRecordTypes: "Excluded Record Types",
        helpExcludedRecordTypes:
            "Contact Record Types excluded from automatic Household creation.",
        mailingListReport: "Household Mailing List Report ID",
        helpMailingListReport:
            "The ID of a Campaign report used for Household-deduplicated mailing lists. The report should be of Campaigns with Contacts, where Member Status does not contain 'Duplicate.'",
        none: "None",
    };

    // --- Wire adapters ---

    @wire(getSettings, { settingsObjectName: "Household_Naming_Settings__c" })
    wiredNamingSettings(result) {
        this._wiredNamingResult = result;
        if (result.data) {
            this._settingsNaming = { ...result.data };
            this._hasError = false;
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    @wire(getSettings, { settingsObjectName: "Households_Settings__c" })
    wiredHHSettings(result) {
        this._wiredHHResult = result;
        if (result.data) {
            this._settingsHH = { ...result.data };
            if (!this._hasError) {
                this._hasError = false;
            }
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    @wire(isAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this._isAdmin = data;
        }
    }

    @wire(getRecordTypeOptions, { sObjectApiName: "Contact" })
    wiredContactRecordTypes({ data, error }) {
        if (data) {
            this._contactRecordTypeOptions = data.map((opt) => ({
                label: opt.label,
                value: opt.value,
            }));
        } else if (error) {
            this._contactRecordTypeOptions = [];
        }
    }

    // --- Computed: loading & permissions ---

    get isLoading() {
        return (!this._settingsNaming || !this._settingsHH) && !this._hasError;
    }

    get hasSettings() {
        return this._settingsNaming && this._settingsHH;
    }

    get canEdit() {
        return this._isAdmin && !this._isEditMode;
    }

    // --- Household Rules options ---

    get householdRulesOptions() {
        return [
            { label: "All Contacts", value: "All_Contacts" },
            { label: "All Individual Contacts", value: "All_Individual_Contacts" },
            { label: "No Contacts", value: "No_Contacts" },
        ];
    }

    // --- Combobox option getters ---

    get nameFormatOptions() {
        return NAME_FORMAT_OPTIONS;
    }

    get formalGreetingOptions() {
        return FORMAL_GREETING_OPTIONS;
    }

    get informalGreetingOptions() {
        return INFORMAL_GREETING_OPTIONS;
    }

    // --- Name Format: combobox + Other logic ---

    _isOtherValue(value, predefinedOptions) {
        if (!value) return false;
        return !predefinedOptions.some(
            (opt) => opt.value === value && opt.value !== OTHER_VALUE
        );
    }

    // Read-only mode
    get nameFormatComboValue() {
        const val = this._settingsNaming?.Household_Name_Format__c;
        if (this._isOtherValue(val, NAME_FORMAT_OPTIONS)) return OTHER_VALUE;
        return val || "";
    }

    get isNameFormatOtherReadOnly() {
        const val = this._settingsNaming?.Household_Name_Format__c;
        return this._isOtherValue(val, NAME_FORMAT_OPTIONS);
    }

    // Edit mode
    get nameFormatComboValueEdit() {
        if (this._nameFormatIsOther) return OTHER_VALUE;
        const val = this._workingCopyNaming?.Household_Name_Format__c;
        if (this._isOtherValue(val, NAME_FORMAT_OPTIONS)) return OTHER_VALUE;
        return val || "";
    }

    get isNameFormatOtherEdit() {
        if (this._nameFormatIsOther) return true;
        const val = this._workingCopyNaming?.Household_Name_Format__c;
        return this._isOtherValue(val, NAME_FORMAT_OPTIONS);
    }

    // --- Formal Greeting: combobox + Other logic ---

    get formalGreetingComboValue() {
        const val = this._settingsNaming?.Formal_Greeting_Format__c;
        if (this._isOtherValue(val, FORMAL_GREETING_OPTIONS)) return OTHER_VALUE;
        return val || "";
    }

    get isFormalGreetingOtherReadOnly() {
        const val = this._settingsNaming?.Formal_Greeting_Format__c;
        return this._isOtherValue(val, FORMAL_GREETING_OPTIONS);
    }

    get formalGreetingComboValueEdit() {
        if (this._formalGreetingIsOther) return OTHER_VALUE;
        const val = this._workingCopyNaming?.Formal_Greeting_Format__c;
        if (this._isOtherValue(val, FORMAL_GREETING_OPTIONS)) return OTHER_VALUE;
        return val || "";
    }

    get isFormalGreetingOtherEdit() {
        if (this._formalGreetingIsOther) return true;
        const val = this._workingCopyNaming?.Formal_Greeting_Format__c;
        return this._isOtherValue(val, FORMAL_GREETING_OPTIONS);
    }

    // --- Informal Greeting: combobox + Other logic ---

    get informalGreetingComboValue() {
        const val = this._settingsNaming?.Informal_Greeting_Format__c;
        if (this._isOtherValue(val, INFORMAL_GREETING_OPTIONS)) return OTHER_VALUE;
        return val || "";
    }

    get isInformalGreetingOtherReadOnly() {
        const val = this._settingsNaming?.Informal_Greeting_Format__c;
        return this._isOtherValue(val, INFORMAL_GREETING_OPTIONS);
    }

    get informalGreetingComboValueEdit() {
        if (this._informalGreetingIsOther) return OTHER_VALUE;
        const val = this._workingCopyNaming?.Informal_Greeting_Format__c;
        if (this._isOtherValue(val, INFORMAL_GREETING_OPTIONS)) return OTHER_VALUE;
        return val || "";
    }

    get isInformalGreetingOtherEdit() {
        if (this._informalGreetingIsOther) return true;
        const val = this._workingCopyNaming?.Informal_Greeting_Format__c;
        return this._isOtherValue(val, INFORMAL_GREETING_OPTIONS);
    }

    // --- Excluded Record Types display ---

    get excludedRecordTypesDisplay() {
        const raw = this._settingsHH?.Household_Creation_Excluded_Recordtypes__c;
        if (!raw) return this.labels.none;
        const ids = raw.split(";").filter(Boolean);
        if (!ids.length) return this.labels.none;
        const map = new Map(
            this._contactRecordTypeOptions.map((o) => [o.value, o.label])
        );
        return ids.map((id) => map.get(id) || id).join(", ");
    }

    get selectedExcludedRecordTypes() {
        const raw =
            this._workingCopyHH?.Household_Creation_Excluded_Recordtypes__c;
        if (!raw) return [];
        return raw.split(";").filter(Boolean);
    }

    // --- Actions ---

    handleEdit() {
        this._workingCopyNaming = { ...this._settingsNaming };
        this._workingCopyHH = { ...this._settingsHH };
        this._nameFormatIsOther = this._isOtherValue(
            this._settingsNaming?.Household_Name_Format__c,
            NAME_FORMAT_OPTIONS
        );
        this._formalGreetingIsOther = this._isOtherValue(
            this._settingsNaming?.Formal_Greeting_Format__c,
            FORMAL_GREETING_OPTIONS
        );
        this._informalGreetingIsOther = this._isOtherValue(
            this._settingsNaming?.Informal_Greeting_Format__c,
            INFORMAL_GREETING_OPTIONS
        );
        this._isEditMode = true;
    }

    handleCancel() {
        this._workingCopyNaming = {};
        this._workingCopyHH = {};
        this._nameFormatIsOther = false;
        this._formalGreetingIsOther = false;
        this._informalGreetingIsOther = false;
        this._isEditMode = false;
    }

    // --- Naming field handlers ---

    handleAdvancedNamingChange(event) {
        this._workingCopyNaming.Advanced_Household_Naming__c =
            event.detail.checked;
    }

    handleNameFormatChange(event) {
        const selected = event.detail.value;
        if (selected === OTHER_VALUE) {
            this._nameFormatIsOther = true;
            this._workingCopyNaming.Household_Name_Format__c = "";
        } else {
            this._nameFormatIsOther = false;
            this._workingCopyNaming.Household_Name_Format__c = selected;
        }
    }

    handleCustomNameFormatChange(event) {
        this._workingCopyNaming.Household_Name_Format__c = event.detail.value;
    }

    handleFormalGreetingChange(event) {
        const selected = event.detail.value;
        if (selected === OTHER_VALUE) {
            this._formalGreetingIsOther = true;
            this._workingCopyNaming.Formal_Greeting_Format__c = "";
        } else {
            this._formalGreetingIsOther = false;
            this._workingCopyNaming.Formal_Greeting_Format__c = selected;
        }
    }

    handleCustomFormalGreetingChange(event) {
        this._workingCopyNaming.Formal_Greeting_Format__c = event.detail.value;
    }

    handleInformalGreetingChange(event) {
        const selected = event.detail.value;
        if (selected === OTHER_VALUE) {
            this._informalGreetingIsOther = true;
            this._workingCopyNaming.Informal_Greeting_Format__c = "";
        } else {
            this._informalGreetingIsOther = false;
            this._workingCopyNaming.Informal_Greeting_Format__c = selected;
        }
    }

    handleCustomInformalGreetingChange(event) {
        this._workingCopyNaming.Informal_Greeting_Format__c =
            event.detail.value;
    }

    handleNameConnectorChange(event) {
        this._workingCopyNaming.Name_Connector__c = event.detail.value;
    }

    handleNameOverrunChange(event) {
        this._workingCopyNaming.Name_Overrun__c = event.detail.value;
    }

    handleContactOverrunCountChange(event) {
        this._workingCopyNaming.Contact_Overrun_Count__c =
            event.detail.value !== "" ? Number(event.detail.value) : null;
    }

    handleImplementingClassChange(event) {
        this._workingCopyNaming.Implementing_Class__c = event.detail.value;
    }

    // --- Household Settings field handlers ---

    handleHouseholdRulesChange(event) {
        this._workingCopyHH.Household_Rules__c = event.detail.value;
    }

    handleExcludedRecordTypesChange(event) {
        this._workingCopyHH.Household_Creation_Excluded_Recordtypes__c =
            event.detail.value.join(";");
    }

    handleMailingListReportChange(event) {
        this._workingCopyHH.Household_Mailing_List_ID__c = event.detail.value;
    }

    // --- Save ---

    async handleSave() {
        this._isSaving = true;
        try {
            // 1. Save Household_Naming_Settings__c
            const namingFields = {
                Advanced_Household_Naming__c:
                    this._workingCopyNaming.Advanced_Household_Naming__c,
                Household_Name_Format__c:
                    this._workingCopyNaming.Household_Name_Format__c || null,
                Formal_Greeting_Format__c:
                    this._workingCopyNaming.Formal_Greeting_Format__c || null,
                Informal_Greeting_Format__c:
                    this._workingCopyNaming.Informal_Greeting_Format__c || null,
                Name_Connector__c:
                    this._workingCopyNaming.Name_Connector__c,
                Name_Overrun__c:
                    this._workingCopyNaming.Name_Overrun__c,
                Contact_Overrun_Count__c:
                    this._workingCopyNaming.Contact_Overrun_Count__c,
                Implementing_Class__c:
                    this._workingCopyNaming.Implementing_Class__c || null,
            };
            await saveSettings({
                settingsObjectName: "Household_Naming_Settings__c",
                fieldValues: namingFields,
            });

            // 2. Save Households_Settings__c
            const hhFields = {
                Household_Rules__c:
                    this._workingCopyHH.Household_Rules__c || null,
                Household_Creation_Excluded_Recordtypes__c:
                    this._workingCopyHH
                        .Household_Creation_Excluded_Recordtypes__c || null,
                Household_Mailing_List_ID__c:
                    this._workingCopyHH.Household_Mailing_List_ID__c || null,
            };
            await saveSettings({
                settingsObjectName: "Households_Settings__c",
                fieldValues: hhFields,
            });

            // 3. Refresh both wires
            await Promise.all([
                refreshApex(this._wiredNamingResult),
                refreshApex(this._wiredHHResult),
            ]);

            this._isEditMode = false;
            this._workingCopyNaming = {};
            this._workingCopyHH = {};
            this._nameFormatIsOther = false;
            this._formalGreetingIsOther = false;
            this._informalGreetingIsOther = false;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Household settings saved.",
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
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return "An unexpected error occurred.";
    }
}
