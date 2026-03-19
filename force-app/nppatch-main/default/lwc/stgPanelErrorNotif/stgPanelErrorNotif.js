import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import resolveErrorRecipient from "@salesforce/apex/NppatchSettingsController.resolveErrorRecipient";
import searchUsers from "@salesforce/apex/NppatchSettingsController.searchUsers";
import searchChatterGroups from "@salesforce/apex/NppatchSettingsController.searchChatterGroups";

import stgNavSystem from "@salesforce/label/c.stgNavSystem";
import stgNavErrorNotify from "@salesforce/label/c.stgNavErrorNotify";

const SETTINGS_OBJECT = "Error_Settings__c";
const ALL_SYS_ADMINS = "All Sys Admins";

const RECIPIENT_TYPE_OPTIONS = [
    { label: "All System Administrators", value: "allSysAdmins" },
    { label: "Specific User", value: "user" },
    { label: "Chatter Group", value: "chatterGroup" },
];

export default class StgPanelErrorNotif extends LightningElement {
    _settings;
    @track _workingCopy = {};
    _hasError = false;
    _errorMessage;
    _wiredSettingsResult;

    _recipientType = "allSysAdmins";
    _recipientLabel = "";
    _recipientSublabel = "";
    _searchTerm = "";
    _searchResults = [];
    _isSearching = false;
    _showDropdown = false;
    _searchTimer;
    _recipientResolved = false;

    labels = {
        sectionLabel: stgNavSystem,
        pageLabel: stgNavErrorNotify,
        storeErrors: "Store Errors",
        errorNotifications: "Error Notifications",
        recipientType: "Send Notifications To",
        selectUser: "Search Users",
        selectGroup: "Search Chatter Groups",
    };

    recipientTypeOptions = RECIPIENT_TYPE_OPTIONS;

    get sectionDescription() {
        return "Error handling controls whether NPPatch logs errors to Error__c records and sends notifications. When error storage is enabled, you can configure who receives notifications when processing errors occur.";
    }

    @wire(getSettings, { settingsObjectName: SETTINGS_OBJECT })
    wiredSettings(result) {
        this._wiredSettingsResult = result;
        if (result.data) {
            this._settings = { ...result.data };
            this._workingCopy = { ...result.data };
            this._hasError = false;
            if (!this._recipientResolved) {
                this._resolveRecipient(result.data.Error_Notifications_To__c);
            }
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    async _resolveRecipient(value) {
        try {
            const resolved = await resolveErrorRecipient({ recipientValue: value || null });
            this._recipientType = resolved.type;
            this._recipientLabel = resolved.label || "";
            this._recipientSublabel = resolved.sublabel || "";
            this._recipientResolved = true;
        } catch (e) {
            this._recipientType = "allSysAdmins";
            this._recipientResolved = true;
        }
    }

    get isLoading() {
        return (!this._settings || !this._recipientResolved) && !this._hasError;
    }

    get storeErrorsValue() {
        return this._workingCopy?.Store_Errors_On__c || false;
    }

    get errorNotificationsValue() {
        return this._workingCopy?.Error_Notifications_On__c || false;
    }

    get isNotifDisabled() {
        return !this._workingCopy?.Store_Errors_On__c;
    }

    get isRecipientDisabled() {
        return !this._workingCopy?.Error_Notifications_On__c;
    }

    get showRecipientSearch() {
        return this._recipientType === "user" || this._recipientType === "chatterGroup";
    }

    get searchPlaceholder() {
        return this._recipientType === "user"
            ? "Type a name to search users..."
            : "Type a name to search Chatter groups...";
    }

    get searchLabel() {
        return this._recipientType === "user" ? this.labels.selectUser : this.labels.selectGroup;
    }

    get hasSearchResults() {
        return this._searchResults.length > 0;
    }

    get selectedRecipientPill() {
        return this._recipientLabel && this._recipientType !== "allSysAdmins" ? this._recipientLabel : null;
    }

    get showSearchInput() {
        return !this.selectedRecipientPill;
    }

    get noResults() {
        return (
            !this._isSearching && this._searchTerm.length >= 2 && this._searchResults.length === 0 && this._showDropdown
        );
    }

    // --- Handlers ---

    handleStoreErrorsChange(event) {
        this._workingCopy = {
            ...this._workingCopy,
            Store_Errors_On__c: event.detail.checked,
            Error_Notifications_On__c: event.detail.checked ? this._workingCopy.Error_Notifications_On__c : false,
        };
    }

    handleErrorNotificationsChange(event) {
        this._workingCopy = {
            ...this._workingCopy,
            Error_Notifications_On__c: event.detail.checked,
        };
    }

    handleRecipientTypeChange(event) {
        this._recipientType = event.detail.value;
        this._searchTerm = "";
        this._searchResults = [];
        this._showDropdown = false;

        if (this._recipientType === "allSysAdmins") {
            this._workingCopy = {
                ...this._workingCopy,
                Error_Notifications_To__c: ALL_SYS_ADMINS,
            };
            this._recipientLabel = "";
            this._recipientSublabel = "";
        } else {
            // Clear the current selection until user picks one
            this._recipientLabel = "";
            this._recipientSublabel = "";
        }
    }

    handleSearchChange(event) {
        const term = event.target.value || "";
        this._searchTerm = term;

        clearTimeout(this._searchTimer);

        if (!term || term.length < 2) {
            this._searchResults = [];
            this._showDropdown = false;
            return;
        }

        this._showDropdown = true;
        this._searchTimer = setTimeout(() => {
            this._performSearch(term);
        }, 300);
    }

    handleSelectResult(event) {
        const value = event.currentTarget.dataset.value;
        const label = event.currentTarget.dataset.label;
        const sublabel = event.currentTarget.dataset.sublabel || "";

        this._workingCopy = {
            ...this._workingCopy,
            Error_Notifications_To__c: value,
        };
        this._recipientLabel = label;
        this._recipientSublabel = sublabel;
        this._searchTerm = "";
        this._searchResults = [];
        this._showDropdown = false;
    }

    handleClearRecipient() {
        this._recipientLabel = "";
        this._recipientSublabel = "";
        this._workingCopy = {
            ...this._workingCopy,
            Error_Notifications_To__c: null,
        };
    }

    async _performSearch(term) {
        this._isSearching = true;
        try {
            const results =
                this._recipientType === "user"
                    ? await searchUsers({ searchTerm: term })
                    : await searchChatterGroups({ searchTerm: term });
            this._searchResults = results;
            this._showDropdown = results.length > 0;
        } catch (e) {
            this._searchResults = [];
            this._showDropdown = false;
        }
        this._isSearching = false;
    }

    // --- Save / Reset ---

    @api
    async save() {
        try {
            await saveSettings({
                settingsObjectName: SETTINGS_OBJECT,
                fieldValues: {
                    Store_Errors_On__c: this._workingCopy.Store_Errors_On__c,
                    Error_Notifications_On__c: this._workingCopy.Error_Notifications_On__c,
                    Error_Notifications_To__c: this._workingCopy.Error_Notifications_To__c || null,
                },
            });
            await refreshApex(this._wiredSettingsResult);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Error notification settings saved.",
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
        this._resolveRecipient(this._settings?.Error_Notifications_To__c);
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
