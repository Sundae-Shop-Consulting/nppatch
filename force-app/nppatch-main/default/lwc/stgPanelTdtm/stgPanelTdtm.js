import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getTriggerHandlers from "@salesforce/apex/NppatchSettingsController.getTriggerHandlers";
import createTriggerHandler from "@salesforce/apex/NppatchSettingsController.createTriggerHandler";
import deleteTriggerHandler from "@salesforce/apex/NppatchSettingsController.deleteTriggerHandler";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";
import searchSObjects from "@salesforce/apex/NppatchSettingsController.searchSObjects";
import searchApexClasses from "@salesforce/apex/NppatchSettingsController.searchApexClasses";
import validateTriggerHandlerClass from "@salesforce/apex/NppatchSettingsController.validateTriggerHandlerClass";

const DATA_COLUMNS = [
    { label: "Object", fieldName: "Object__c", type: "text" },
    { label: "Class", fieldName: "Class__c", type: "text" },
    { label: "Load Order", fieldName: "Load_Order__c", type: "number" },
    { label: "Trigger Action", fieldName: "Trigger_Action__c", type: "text" },
    { label: "Active", fieldName: "Active__c", type: "boolean" },
    { label: "Async", fieldName: "Asynchronous__c", type: "boolean" },
    { label: "User Managed", fieldName: "User_Managed__c", type: "boolean" },
];

const ACTION_COLUMN = {
    type: "action",
    typeAttributes: {
        rowActions: [{ label: "Delete", name: "delete" }],
    },
};

const BEFORE_ACTION_OPTIONS = [
    { label: "Before Insert", value: "BeforeInsert" },
    { label: "Before Update", value: "BeforeUpdate" },
    { label: "Before Delete", value: "BeforeDelete" },
];

const AFTER_ACTION_OPTIONS = [
    { label: "After Insert", value: "AfterInsert" },
    { label: "After Update", value: "AfterUpdate" },
    { label: "After Delete", value: "AfterDelete" },
    { label: "After Undelete", value: "AfterUndelete" },
];

export default class StgPanelTDTM extends LightningElement {
    _settings;
    _wiredResult;
    _canEdit = false;
    _isCreating = false;
    _isSaving = false;
    _hasError = false;
    _errorMessage = "";
    @track _newRecord = {
        Object__c: "",
        Class__c: "",
        Load_Order__c: 1,
        Trigger_Action__c: "",
        Active__c: true,
        Asynchronous__c: false,
    };

    // Typeahead state — Object
    _objectSearchTerm = "";
    _objectResults = [];
    _showObjectDropdown = false;
    _objectSearchTimer;
    _objectLabel = "";

    // Typeahead state — Class
    _classSearchTerm = "";
    _classResults = [];
    _showClassDropdown = false;
    _classSearchTimer;

    // Multiselect state — Trigger Actions (split before/after)
    _selectedBeforeActions = [];
    _selectedAfterActions = [];

    beforeActionOptions = BEFORE_ACTION_OPTIONS;
    afterActionOptions = AFTER_ACTION_OPTIONS;

    labels = {
        sectionLabel: "System Tools",
        pageLabel: "Trigger Configuration",
        description:
            "Trigger Configuration (TDTM) controls which Apex trigger handlers execute and in what order. " +
            "Each handler is tied to a specific SObject and set of trigger events. The Active flag enables or disables " +
            "individual handlers. Use caution when modifying these settings \u2014 disabling core handlers may break NPPatch functionality.",
    };

    @wire(isAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this._canEdit = data;
        }
    }

    @wire(getTriggerHandlers)
    wiredSettings(result) {
        this._wiredResult = result;
        if (result.data) {
            this._settings = result.data;
            this._hasError = false;
        } else if (result.error) {
            this._hasError = true;
            this._errorMessage = this._extractError(result.error);
        }
    }

    get isLoading() {
        return !this._settings && !this._hasError;
    }

    get hasRecords() {
        return this._settings && this._settings.length > 0;
    }

    get canEdit() {
        return this._canEdit;
    }

    get columns() {
        if (this._canEdit) {
            return [...DATA_COLUMNS, ACTION_COLUMN];
        }
        return DATA_COLUMNS;
    }

    // --- Object typeahead ---

    get showObjectPill() {
        return !!this._newRecord.Object__c;
    }

    get objectPillLabel() {
        if (this._objectLabel) {
            return this._objectLabel + "  " + this._newRecord.Object__c;
        }
        return this._newRecord.Object__c;
    }

    get showObjectSearch() {
        return !this._newRecord.Object__c;
    }

    handleObjectSearchChange(event) {
        const term = event.target.value || "";
        this._objectSearchTerm = term;
        clearTimeout(this._objectSearchTimer);
        if (term.length < 2) {
            this._objectResults = [];
            this._showObjectDropdown = false;
            return;
        }
        this._showObjectDropdown = true;
        this._objectSearchTimer = setTimeout(() => {
            this._performObjectSearch(term);
        }, 300);
    }

    async _performObjectSearch(term) {
        try {
            this._objectResults = await searchSObjects({ searchTerm: term });
            this._showObjectDropdown = this._objectResults.length > 0;
        } catch (_e) {
            this._objectResults = [];
            this._showObjectDropdown = false;
        }
    }

    handleSelectObject(event) {
        const value = event.currentTarget.dataset.value;
        const label = event.currentTarget.dataset.label || "";
        this._newRecord = { ...this._newRecord, Object__c: value };
        this._objectLabel = label;
        this._objectSearchTerm = "";
        this._objectResults = [];
        this._showObjectDropdown = false;
    }

    handleClearObject() {
        this._newRecord = { ...this._newRecord, Object__c: "" };
        this._objectLabel = "";
    }

    // --- Class typeahead ---

    get showClassPill() {
        return !!this._newRecord.Class__c;
    }

    get showClassSearch() {
        return !this._newRecord.Class__c;
    }

    handleClassSearchChange(event) {
        const term = event.target.value || "";
        this._classSearchTerm = term;
        clearTimeout(this._classSearchTimer);
        if (term.length < 2) {
            this._classResults = [];
            this._showClassDropdown = false;
            return;
        }
        this._showClassDropdown = true;
        this._classSearchTimer = setTimeout(() => {
            this._performClassSearch(term);
        }, 300);
    }

    async _performClassSearch(term) {
        try {
            this._classResults = await searchApexClasses({ searchTerm: term });
            this._showClassDropdown = this._classResults.length > 0;
        } catch (_e) {
            this._classResults = [];
            this._showClassDropdown = false;
        }
    }

    handleSelectClass(event) {
        const value = event.currentTarget.dataset.value;
        this._newRecord = { ...this._newRecord, Class__c: value };
        this._classSearchTerm = "";
        this._classResults = [];
        this._showClassDropdown = false;
    }

    handleClearClass() {
        this._newRecord = { ...this._newRecord, Class__c: "" };
    }

    // --- Trigger Action multiselect (split before/after) ---

    handleBeforeActionChange(event) {
        this._selectedBeforeActions = event.detail.value;
        this._updateTriggerActionField();
    }

    handleAfterActionChange(event) {
        this._selectedAfterActions = event.detail.value;
        this._updateTriggerActionField();
    }

    _updateTriggerActionField() {
        const all = [...this._selectedBeforeActions, ...this._selectedAfterActions];
        this._newRecord = {
            ...this._newRecord,
            Trigger_Action__c: all.join(";"),
        };
    }

    // --- Other form fields ---

    handleNew() {
        this._isCreating = true;
        this._newRecord = {
            Object__c: "",
            Class__c: "",
            Load_Order__c: 1,
            Trigger_Action__c: "",
            Active__c: true,
            Asynchronous__c: false,
        };
        this._selectedBeforeActions = [];
        this._selectedAfterActions = [];
        this._objectSearchTerm = "";
        this._objectResults = [];
        this._showObjectDropdown = false;
        this._objectLabel = "";
        this._classSearchTerm = "";
        this._classResults = [];
        this._showClassDropdown = false;
    }

    handleCancelNew() {
        this._isCreating = false;
    }

    handleNewLoadOrderChange(event) {
        this._newRecord = { ...this._newRecord, Load_Order__c: event.detail.value };
    }

    handleNewActiveChange(event) {
        this._newRecord = { ...this._newRecord, Active__c: event.detail.checked };
    }

    handleNewAsynchronousChange(event) {
        this._newRecord = { ...this._newRecord, Asynchronous__c: event.detail.checked };
    }

    async handleSaveNew() {
        if (!this._newRecord.Object__c || !this._newRecord.Class__c || this._newRecord.Load_Order__c == null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: "Object, Class, and Load Order are required.",
                    variant: "error",
                })
            );
            return;
        }
        if (!this._newRecord.Trigger_Action__c) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: "Select at least one Trigger Action.",
                    variant: "error",
                })
            );
            return;
        }

        this._isSaving = true;
        try {
            // Validate class implements TDTM_Runnable
            const isValid = await validateTriggerHandlerClass({ className: this._newRecord.Class__c });
            if (!isValid) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: `"${this._newRecord.Class__c}" does not implement the TDTM_Runnable interface. Trigger handler classes must extend TDTM_Runnable.`,
                        variant: "error",
                    })
                );
                this._isSaving = false;
                return;
            }

            await createTriggerHandler({
                fieldValues: this._newRecord,
            });
            await refreshApex(this._wiredResult);
            this._isCreating = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Trigger handler created.",
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

    async handleRowAction(event) {
        if (event.detail.action.name === "delete") {
            try {
                await deleteTriggerHandler({
                    recordId: event.detail.row.Id,
                });
                await refreshApex(this._wiredResult);
                this.dispatchEvent(
                    new ShowToastEvent({ title: "Success", message: "Record deleted.", variant: "success" })
                );
            } catch (error) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: this._extractError(error),
                        variant: "error",
                    })
                );
            }
        }
    }

    _extractError(error) {
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return "An unexpected error occurred.";
    }
}
