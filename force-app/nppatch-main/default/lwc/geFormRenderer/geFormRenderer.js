import { LightningElement, api, track, wire } from "lwc";

import upsertDataImport from "@salesforce/apex/GE_GiftEntryController.upsertDataImport";
import PAYMENT_METHOD from "@salesforce/schema/DataImport__c.Payment_Method__c";
import DATA_IMPORT_BATCH_ALLOW_RECURRING_DONATIONS from "@salesforce/schema/DataImportBatch__c.Allow_Recurring_Donations__c";

import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { convertBDIToWidgetJson } from "./geFormRendererHelper";
import GeFormElementHelper from "./geFormElementHelper";
import GeFormService from "c/geFormService";
import GeLabelService from "c/geLabelService";
import messageLoading from "@salesforce/label/c.labelMessageLoading";
import geMakeRecurring from "@salesforce/label/c.geMakeRecurring";
import btnContinue from "@salesforce/label/c.btnContinue";
import geRecurringGiftModalWarning from "@salesforce/label/c.geRecurringGiftModalWarning";
import geRecurringScheduleInformation from "@salesforce/label/c.geRecurringScheduleInformation";
import {
    DONATION_DONOR_FIELDS,
    DONATION_DONOR,
    handleError,
    getRecordFieldNames,
    setRecordValuesOnTemplate,
    checkPermissionErrors,
    isTrueFalsePicklist,
    trueFalsePicklistOptions,
    CHECKBOX_TRUE,
    CHECKBOX_FALSE,
    PICKLIST_TRUE,
    PICKLIST_FALSE,
} from "c/utilTemplateBuilder";
import { registerListener, fireEvent } from "c/pubsubNoPageRef";
import {
    getQueryParameters,
    isEmpty,
    isNotEmpty,
    format,
    isUndefined,
    hasNestedProperty,
    deepClone,
    validateJSONString,
    relatedRecordFieldNameFor,
    apiNameFor,
    showToast,
    isEmptyObject,
} from "c/utilCommon";
import ExceptionDataError from "./exceptionDataError";
import Gift from "c/geGift";
import { getRecord } from "lightning/uiRecordApi";
import FORM_TEMPLATE_FIELD from "@salesforce/schema/DataImportBatch__c.Form_Template__c";
import BATCH_DEFAULTS_FIELD from "@salesforce/schema/DataImportBatch__c.Batch_Defaults__c";
import STATUS_FIELD from "@salesforce/schema/DataImport__c.Status__c";
import NPSP_DATA_IMPORT_BATCH_FIELD from "@salesforce/schema/DataImport__c.NPPatch_Data_Import_Batch__c";

import DATA_IMPORT_RECURRING_DONATION_PAYMENT_METHOD from "@salesforce/schema/DataImport__c.Recurring_Donation_Payment_Method__c";
import DATA_IMPORT_RECURRING_DONATION_RECURRING_AMOUNT from "@salesforce/schema/DataImport__c.Recurring_Donation_Amount__c";
import DATA_IMPORT_RECURRING_DONATION_DATE_ESTABLISHED from "@salesforce/schema/DataImport__c.Recurring_Donation_Date_Established__c";

import DATA_IMPORT_ADDITIONAL_OBJECT_FIELD from "@salesforce/schema/DataImport__c.Additional_Object_JSON__c";
import DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD from "@salesforce/schema/DataImport__c.Account1Imported__c";
import DATA_IMPORT_CONTACT1_IMPORTED_FIELD from "@salesforce/schema/DataImport__c.Contact1Imported__c";
import DATA_IMPORT_DONATION_IMPORTED_FIELD from "@salesforce/schema/DataImport__c.DonationImported__c";
import DATA_IMPORT_PAYMENT_IMPORTED_FIELD from "@salesforce/schema/DataImport__c.PaymentImported__c";
import DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD from "@salesforce/schema/DataImport__c.DonationImportStatus__c";
import DATA_IMPORT_PAYMENT_IMPORT_STATUS_FIELD from "@salesforce/schema/DataImport__c.PaymentImportStatus__c";
import DATA_IMPORT_DONATION_DONOR_FIELD from "@salesforce/schema/DataImport__c.Donation_Donor__c";
import DATA_IMPORT_DONATION_AMOUNT from "@salesforce/schema/DataImport__c.Donation_Amount__c";
import DATA_IMPORT_DONATION_DATE from "@salesforce/schema/DataImport__c.Donation_Date__c";
import DATA_IMPORT_DONATION_RECORD_TYPE_NAME from "@salesforce/schema/DataImport__c.Donation_Record_Type_Name__c";
import OPP_PAYMENT_AMOUNT from "@salesforce/schema/OppPayment__c.Payment_Amount__c";
import SCHEDULED_DATE from "@salesforce/schema/OppPayment__c.Scheduled_Date__c";
import { GIFT_STATUSES } from "c/geConstants";

import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Account.Name";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import CONTACT_NAME_FIELD from "@salesforce/schema/Contact.Name";
import OPP_PAYMENT_OBJECT from "@salesforce/schema/OppPayment__c";
import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";
import PARENT_OPPORTUNITY_FIELD from "@salesforce/schema/OppPayment__c.Opportunity__c";
import DATA_IMPORT_OBJECT from "@salesforce/schema/DataImport__c";
import OPP_PRIMARY_CONTACT from "@salesforce/schema/Opportunity.Primary_Contact__c";

// Labels are used in BDI_MatchDonations class
import userSelectedMatch from "@salesforce/label/c.bdiMatchedByUser";
import userSelectedNewOpp from "@salesforce/label/c.bdiMatchedByUserNewOpp";
import applyNewPayment from "@salesforce/label/c.bdiMatchedApplyNewPayment";
import bgeGridGiftSaved from "@salesforce/label/c.bgeGridGiftSaved";
import accountDonorSelectionMismatch from "@salesforce/label/c.geErrorDonorMismatch";
import CURRENCY from "@salesforce/i18n/currency";

const mode = {
    CREATE: "create",
    UPDATE: "update",
};
const DONATION_DONOR_TYPE_ENUM = Object.freeze({
    ACCOUNT1: "Account1",
    CONTACT1: "Contact1",
});

const FORM_STATE_IMMUTABLE_FIELDS_API_NAMES = [NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName];

const EXPANDABLE_SECTION_CONTAINER = "expandableSectionContainer";

export default class GeFormRenderer extends LightningElement {
    // these three fields are used to query the donor record
    // when opened from an Account or Contact
    _donorRecordId;
    @api get donorRecordId() {
        return this._donorRecordId;
    }
    set donorRecordId(value) {
        this._donorRecordId = value;
    }

    _donorRecord;
    @api get donorRecord() {
        return this._donorRecord;
    }
    set donorRecord(value) {
        this._donorRecord = value;
    }

    _loadingText;
    @api get loadingText() {
        return this._loadingText;
    }
    set loadingText(value) {
        this._loadingText = value;
    }

    fieldNames = [ACCOUNT_NAME_FIELD, CONTACT_NAME_FIELD];

    _sections = [];
    @api get sections() {
        return this._sections;
    }
    set sections(value) {
        this._sections = value;
    }

    _showSpinner = false;
    @api get showSpinner() {
        return this._showSpinner;
    }
    set showSpinner(value) {
        this._showSpinner = value;
    }

    @api batchId;

    _hasPageLevelError = false;
    @api get hasPageLevelError() {
        return this._hasPageLevelError;
    }
    set hasPageLevelError(value) {
        this._hasPageLevelError = value;
    }

    _pageLevelErrorMessageList = [];
    @api get pageLevelErrorMessageList() {
        return this._pageLevelErrorMessageList;
    }
    set pageLevelErrorMessageList(value) {
        this._pageLevelErrorMessageList = value;
    }

    @api batchCurrencyIsoCode;
    @api saveDisabled = false;
    @api isMakeRecurringButtonDisabled = false;

    @track isPermissionError = false;
    @track permissionErrorTitle;
    @track permissionErrorMessage;
    @track formTemplate;
    @track fieldMappings;
    @track ready = false;
    @track name = "";
    @track description = "";
    @track version = "";

    _openedGiftId;
    @track _batch = {};

    erroredFields = [];
    CUSTOM_LABELS = {
        ...GeLabelService.CUSTOM_LABELS,
        messageLoading,
        geMakeRecurring,
    };

    _isFormCollapsed = false;
    _shouldInformParent = true;
    _isInvalidDonorSelected = false;

    get hasSchedule() {
        const schedule = this._giftInView?.schedule;
        return schedule ? Object.keys(schedule).length > 0 : false;
    }

    set selectedDonationOrPaymentRecord(record) {
        if (record.new === true) {
            this.setCreateNewOpportunityInFormState();
        } else if (this.isAPaymentId(record.fields.Id)) {
            this.validateDonorSelection(record.fields);
            this.setSelectedPaymentInFormState(record.fields);
            this.loadPaymentAndParentDonationFieldValues(record.fields);
        } else if (this.isAnOpportunityId(record.fields.Id)) {
            this.setSelectedDonationInFormState(record.fields, record.fields.applyPayment);
            this.loadSelectedDonationFieldValues(record.fields);
        } else {
            throw new Error("Unsupported selected donation type!");
        }

        const reviewDonationsChangeEvent = new CustomEvent("reviewdonationschange", { detail: { record: record } });
        this.dispatchEvent(reviewDonationsChangeEvent);
    }

    validateDonorSelection(fields) {
        if (this.selectedDonationHasPrimaryContact(fields) && this.isDonorTypeAccount()) {
            this._isInvalidDonorSelected = true;
        }
    }

    selectedDonationHasPrimaryContact(fields) {
        return fields[apiNameFor(PARENT_OPPORTUNITY_FIELD).replace("__c", "__r")][apiNameFor(OPP_PRIMARY_CONTACT)];
    }

    setSelectedPaymentInFormState(record) {
        const updatedData = {
            [apiNameFor(DATA_IMPORT_PAYMENT_IMPORTED_FIELD)]: record.Id,
            [apiNameFor(DATA_IMPORT_DONATION_IMPORTED_FIELD)]: record[apiNameFor(PARENT_OPPORTUNITY_FIELD)],
            [apiNameFor(DATA_IMPORT_PAYMENT_IMPORT_STATUS_FIELD)]: userSelectedMatch,
            [apiNameFor(DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD)]: userSelectedMatch,
        };
        this.updateFormState(updatedData);
    }

    loadPaymentAndParentDonationFieldValues(record) {
        this.loadSelectedRecordFieldValues(
            apiNameFor(DATA_IMPORT_DONATION_IMPORTED_FIELD),
            record[apiNameFor(PARENT_OPPORTUNITY_FIELD)]
        );

        this.loadSelectedRecordFieldValues(apiNameFor(DATA_IMPORT_PAYMENT_IMPORTED_FIELD), record.Id);
    }

    setSelectedDonationInFormState(record, isApplyNewPayment = false) {
        this.resetDonationAndPaymentImportedFields();

        this.updateFormState({
            [apiNameFor(DATA_IMPORT_DONATION_IMPORTED_FIELD)]: record.Id,
            [apiNameFor(DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD)]: isApplyNewPayment
                ? applyNewPayment
                : userSelectedMatch,
        });
    }

    loadSelectedDonationFieldValues(record) {
        this.loadSelectedRecordFieldValues(apiNameFor(DATA_IMPORT_DONATION_IMPORTED_FIELD), record.Id);
    }

    /*******************************************************************************
     * @description Object used to hold current values for all fields on the form.
     */
    @track
    _formState = {};

    get title() {
        return hasNestedProperty(this.donorRecord, "fields", "Name", "value")
            ? GeLabelService.format(this.CUSTOM_LABELS.geHeaderMatchingGiftBy, [this.donorRecord.fields.Name.value])
            : this.CUSTOM_LABELS.commonNewGift;
    }

    get isSingleGiftEntry() {
        return !this.batchId;
    }

    get cancelButtonText() {
        return this.isSingleGiftEntry ? this.CUSTOM_LABELS.commonCancel : this.CUSTOM_LABELS.geButtonCancelAndClear;
    }

    get isRecurringGiftsEnabled() {
        return this._batch[apiNameFor(DATA_IMPORT_BATCH_ALLOW_RECURRING_DONATIONS)];
    }

    @wire(getRecord, { recordId: "$donorRecordId", optionalFields: "$fieldNames" })
    wiredGetRecordMethod({ error, data }) {
        if (data) {
            this._donorRecord = data;
            this.initializeForm(this.formTemplate, this.fieldMappings);
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }

    connectedCallback() {
        this._connected = true;
        registerListener("geModalCloseEvent", this.handleChangeSelectedDonation, this);
        registerListener("formRendererReset", this.reset, this);
        registerListener("formfieldchange", this.handleFormFieldChange, this);
        registerListener("formwidgetchange", this.handleFormWidgetChange, this);

        GeFormService.getFormTemplate().then((response) => {
            if (this.batchId) {
                // When the form is being used for Batch Gift Entry, the Form Template JSON
                // uses the @wire service below to retrieve the Template using the Template Id
                // stored on the Batch.
                return;
            }

            // check if there is a record id in the url
            this._donorRecordId = getQueryParameters().c__donorRecordId;
            const donorApiName = getQueryParameters().c__apiName;
            if (donorApiName) {
                this.initializeDonationDonorTypeInFormState(donorApiName);
            }

            // read the template header info
            if (response !== null && typeof response !== "undefined") {
                this.formTemplate = response.formTemplate;
                this.fieldMappings = response.fieldMappingSetWrapper.fieldMappingByDevName;

                const errorObject = checkPermissionErrors(this.formTemplate);
                if (errorObject) {
                    this.setPermissionsError(errorObject);

                    return;
                }

                // get the target field names to be used by getRecord
                const fieldNamesFromTemplate = getRecordFieldNames(this.formTemplate, this.fieldMappings, donorApiName);
                this.fieldNames = [...this.fieldNames, ...fieldNamesFromTemplate];
                if (isEmpty(this.donorRecordId)) {
                    // if we don't have a donor record, it's ok to initialize the form now
                    // otherwise the form will be initialized after wiredGetRecordMethod completes
                    this.initializeForm(this.formTemplate);
                }
            }
        });
    }

    handleMakeGiftRecurring() {
        this.openRecurringGiftModal(false);
    }

    handleEditSchedule() {
        this.openRecurringGiftModal(true);
    }

    createRecurrence(scheduleData) {
        this.dispatchEvent(new CustomEvent("addschedule", { detail: scheduleData }));
    }

    openRecurringGiftModal(isEdit) {
        if (this.shouldDisplayWarningForRecurringGiftModal()) {
            this.displayWarningForRecurringGiftModal();
            return;
        }

        const componentProperties = {
            cancelCallback: () => {
                fireEvent(this.pageRef, "geModalCloseEvent", {});
            },
            createRecurrenceCallback: (scheduleData) => {
                this.createRecurrence(scheduleData);
            },
            giftInView: this.giftInView,
        };

        if (isEdit) {
            componentProperties.schedule = this.giftInView.schedule;
        }

        const detail = {
            modalProperties: {
                header: geRecurringScheduleInformation,
                componentName: "geModalRecurringDonation",
                showCloseButton: true,
            },
            componentProperties,
        };
        this.dispatchEvent(new CustomEvent("togglemodal", { detail }));
    }

    shouldDisplayWarningForRecurringGiftModal() {
        return this.hasSoftCredits();
    }

    displayWarningForRecurringGiftModal() {
        this.toggleModalByComponentName("geModalPrompt", {
            variant: "warning",
            title: this.CUSTOM_LABELS.commonWarning,
            message: geRecurringGiftModalWarning,
            buttons: [
                {
                    label: btnContinue,
                    action: () => {
                        fireEvent(this.pageRef, "geModalCloseEvent", {});
                    },
                },
            ],
        });
    }

    hasSoftCredits() {
        if (this.giftInView?.softCredits) {
            const softCredits = JSON.parse(this.giftInView.softCredits);
            return softCredits.length > 0;
        }
        return false;
    }

    handleRemoveSchedule() {
        this.dispatchEvent(new CustomEvent("removeschedule", { detail: {} }));
    }

    initializeDonationDonorTypeInFormState(donorApiName) {
        const updates = new Map();
        updates.set(DATA_IMPORT_DONATION_DONOR_FIELD, donorApiName);
        this.updateFormState(updates);
    }

    initializeForm(formTemplate, fieldMappings) {
        // read the template header info
        this.ready = true;
        this.name = formTemplate.name;
        this.description = formTemplate.description;
        this.version = formTemplate.layout.version;

        if (typeof formTemplate.layout !== "undefined" && Array.isArray(formTemplate.layout.sections)) {
            // add record data to the template fields

            if (isNotEmpty(fieldMappings) && isNotEmpty(this.donorRecord)) {
                this._sections = setRecordValuesOnTemplate(
                    formTemplate.layout.sections,
                    fieldMappings,
                    this.donorRecord
                );
            } else {
                this._sections = formTemplate.layout.sections;
            }

            if (!this.isSingleGiftEntry) {
                this._sections = this.prepareFormForBatchMode(formTemplate.layout.sections);
                this.dispatchEvent(new CustomEvent("sectionsretrieved"));
            }
        }

        this._sections = this.appendRecordTypeLocationInfoToPicklistElements();
        this.initializeFormState();
    }

    appendRecordTypeLocationInfoToPicklistElements() {
        this.sections.forEach((section) => {
            section.elements.forEach((element) => {
                this.enrichElement(element);
            });
        });

        return [...this.sections];
    }

    appendRecordTypeLocationInfo(element) {
        const fieldMappingDevName = element.dataImportFieldMappingDevNames && element.dataImportFieldMappingDevNames[0];

        if (fieldMappingDevName) {
            element.siblingRecordTypeField = this.siblingRecordTypeFieldFor(fieldMappingDevName);
            element.parentRecordField = this.parentRecordFieldFor(fieldMappingDevName);
        }
    }

    enrichElement(element) {
        this.appendRecordTypeLocationInfo(element);
        this.appendElementHelperData(element);
    }

    appendElementHelperData(element) {
        const helper = new GeFormElementHelper(element);
        element.isRenderable = helper.isRenderable();
        if (helper.isTrueFalsePicklist()) {
            element.picklistOptionsOverride = trueFalsePicklistOptions();
        }
    }

    setPermissionsError(errorObject) {
        if (errorObject) {
            this.isPermissionError = true;
            this.permissionErrorTitle = errorObject.errorTitle;
            this.permissionErrorMessage = errorObject.errorMessage;
        }
    }

    @wire(getRecord, {
        recordId: "$batchId",
        fields: [FORM_TEMPLATE_FIELD, BATCH_DEFAULTS_FIELD],
        optionalFields: [DATA_IMPORT_BATCH_ALLOW_RECURRING_DONATIONS],
    })
    wiredBatch({ data, error }) {
        if (data) {
            this._batch[apiNameFor(BATCH_DEFAULTS_FIELD)] = data.fields[apiNameFor(BATCH_DEFAULTS_FIELD)].value;
            this._batch[apiNameFor(DATA_IMPORT_BATCH_ALLOW_RECURRING_DONATIONS)] =
                data?.fields[apiNameFor(DATA_IMPORT_BATCH_ALLOW_RECURRING_DONATIONS)]?.value;

            GeFormService.getFormTemplateById(data.fields[apiNameFor(FORM_TEMPLATE_FIELD)].value)
                .then((formTemplate) => {
                    this.formTemplate = formTemplate;

                    const errorObject = checkPermissionErrors(formTemplate);
                    if (errorObject) {
                        this.dispatchEvent(new CustomEvent("permissionerror"));
                        this.setPermissionsError(errorObject);
                    }
                    this.initializeForm(formTemplate, GeFormService.fieldMappings);
                })
                .catch((err) => {
                    handleError(err);
                });
        } else if (error) {
            handleError(error);
        }
    }

    handleCancel() {
        if (this.isSingleGiftEntry) {
            const originatedFromRecordDetailPage = getQueryParameters().c__donorRecordId;
            if (originatedFromRecordDetailPage) {
                this.goToRecordDetailPage(originatedFromRecordDetailPage);
            } else {
                this.goToLandingPage();
            }
        } else {
            this.dispatchEvent(new CustomEvent("clearcurrentgift"));
            this.reset();
            this.initializeFormState();
        }
    }

    goToRecordDetailPage(recordId) {
        if (!recordId) {
            return;
        }
        const navigateEvent = new CustomEvent("navigate", {
            detail: {
                to: "recordPage",
                recordId: recordId,
            },
        });
        this.dispatchEvent(navigateEvent);
    }

    goToLandingPage() {
        const navigateEvent = new CustomEvent("navigate", {
            detail: {
                to: "landingPage",
            },
        });
        this.dispatchEvent(navigateEvent);
    }

    /*******************************************************************************
     * @description Dispatches an event and notifies the parent component to display
     * an aura overlay library modal with a lightning web component in its body.
     *
     * @param {string} modalBodyComponentName: Name of the LWC to render in the
     * overlay library modal's body.
     */
    toggleModalByComponentName(modalBodyComponentName, componentProperties) {
        const detail = {
            modalProperties: {
                componentName: modalBodyComponentName,
                showCloseButton: false,
            },
            componentProperties,
        };
        this.dispatchEvent(new CustomEvent("togglemodal", { detail }));
    }

    handleCatchOnSave(error) {
        // var inits
        const sectionsList = this.template.querySelectorAll("c-ge-form-section");
        const exceptionWrapper = new ExceptionDataError(error);
        const allDisplayedFields = this.getDisplayedFieldsMappedByAPIName(sectionsList);
        this._hasPageLevelError = true;

        if (isNotEmpty(exceptionWrapper.exceptionType)) {
            // Check to see if there are any field level errors
            if (
                Object.entries(exceptionWrapper.DMLErrorFieldNameMapping).length === undefined ||
                Object.entries(exceptionWrapper.DMLErrorFieldNameMapping).length === 0
            ) {
                // validation rules on Target Objects shows up here
                // unfortunately currently it doesnt bring field info yet
                if (isNotEmpty(exceptionWrapper.errorMessage)) {
                    let errorMessage = exceptionWrapper.errorMessage;

                    const errorMessageObject = validateJSONString(exceptionWrapper.errorMessage);
                    if (errorMessageObject) {
                        errorMessage = errorMessageObject.errorMessage;
                    }

                    this.addPageLevelErrorMessage({ errorMessage, index: this.pageLevelErrorMessageList.length });
                }

                // If there are no specific fields the error has to go to,
                // put it on the page level error message.
                for (const dmlIndex in exceptionWrapper.DMLErrorMessageMapping) {
                    if (Object.prototype.hasOwnProperty.call(exceptionWrapper.DMLErrorMessageMapping, dmlIndex)) {
                        const errorMessage = exceptionWrapper.DMLErrorMessageMapping[dmlIndex];
                        const index = dmlIndex + 1;
                        this.addPageLevelErrorMessage({ errorMessage, index });
                    }
                }
            } else {
                // If there is a specific field that each error is supposed to go to,
                // show it on the field on the page.
                // If it is not on the page to show, display it on the page level.
                for (const key in exceptionWrapper.DMLErrorFieldNameMapping) {
                    if (Object.prototype.hasOwnProperty.call(exceptionWrapper.DMLErrorFieldNameMapping, key)) {
                        // List of fields with this error
                        const fieldList = exceptionWrapper.DMLErrorFieldNameMapping[key];
                        // Error message for the field.
                        const errorMessage = exceptionWrapper.DMLErrorMessageMapping[key];
                        // Errored fields that are not displayed
                        const hiddenFieldList = [];

                        fieldList.forEach((fieldWithError) => {
                            // Go to the field and set the error message using setCustomValidity
                            if (fieldWithError in allDisplayedFields) {
                                const fieldInput = allDisplayedFields[fieldWithError];
                                this.erroredFields.push(fieldInput);
                                fieldInput.setCustomValidity(errorMessage);
                            } else {
                                // Keep track of errored fields that are not displayed.
                                hiddenFieldList.push(fieldWithError);
                            }
                        });

                        // If there are hidden fields, display the error message at the page level.
                        // With the fields noted.
                        if (hiddenFieldList.length > 0) {
                            const combinedFields = hiddenFieldList.join(", ");
                            this.addPageLevelErrorMessage({
                                errorMessage: `${errorMessage} [${combinedFields}]`,
                                index: key,
                            });
                        }
                    }
                }
            }
        } else {
            this.addPageLevelErrorMessage({ errorMessage: exceptionWrapper.errorMessage, index: 0 });
        }

        // focus either the page level or field level error message somehow
        window.scrollTo(0, 0);
    }

    /*******************************************************************************
     * @description Add an error message to the overall page level error messages
     * array.
     *
     * @param {*} errorObject
     */
    addPageLevelErrorMessage(errorObject) {
        errorObject.index = errorObject.index ? errorObject.index : 0;
        this._pageLevelErrorMessageList = [...this.pageLevelErrorMessageList, { ...errorObject }];
        this._hasPageLevelError = true;
    }

    /*******************************************************************************
     * @description Handles the form save action. Builds a data import record and
     * calls handlers for Batch Gift and Single Gift depending on the form's mode.
     *
     * @param {object} event: Onclick event from the form save button
     */
    async handleSave(event) {
        const sectionsList = this.template.querySelectorAll("c-ge-form-section");
        const isFormReadyToSave = this.prepareFormForSave(sectionsList);

        if (isFormReadyToSave) {
            // Disable save button
            this._loadingText = "";
            event.target.disable = true; /* @todo Possible existing bug?  Is this a typo?  Should this be setting event.target.disabled = true ? */
            const formControls = this.getFormControls(event);
            formControls.toggleSpinner();

            if (this.batchId) {
                await this.submitBatch(formControls);
            } else {
                await this.submitSingleGift();
            }
        }
    }

    async submitBatch(formControls) {
        try {
            await this.saveDataImport(this.saveableFormState());
            await this.prepareForBatchGiftSave(this.saveableFormState(), formControls);
        } catch (err) {
            this.disabled = false; /* @todo Possible existing bug?  There is no disabled property on this class.  What is `this` bound to when this is executed? */
            this.toggleSpinner();
            this.handleCatchOnSave(err);
        }
    }

    async prepareForBatchGiftSave(dataImportRecord, formControls) {
        // reset function for callback
        const reset = () => this.reset();
        // handle error on callback from promise
        const handleCatchError = (err) => this.handleCatchOnSave(err);

        this.dispatchEvent(
            new CustomEvent("submit", {
                detail: {
                    dataImportRecord,
                    success: () => {
                        formControls.enableSaveButton();
                        formControls.toggleSpinner();
                        reset();

                        const toastMessage = bgeGridGiftSaved;

                        showToast(this.CUSTOM_LABELS.PageMessagesConfirm, toastMessage, "success", "dismissible", null);
                    },
                    error: (error) => {
                        formControls.enableSaveButton();
                        formControls.toggleSpinner();
                        handleCatchError(error);
                    },
                },
            })
        );
    }

    /*******************************************************************************
     * @description Clears existing errors from the form and re-validates all form
     * sections.
     *
     * @param {list} sectionsList: List of all the form sections
     *
     * @return {boolean}: True if the form is ready for a save attempt.
     */
    prepareFormForSave(sectionsList) {
        // clean errors present on form
        this.clearErrors();
        // apply custom and standard field validation
        return this.isFormValid(sectionsList);
    }

    /*******************************************************************************
     * @description Collects form controls for toggling the spinner and enabling
     * the form save button in one object.
     *
     * @param {object} event: Onclick event from the form save button
     *
     * @return {object}: An object with methods that toggle the form lightning
     * spinner and enables the form save button.
     */
    getFormControls(event) {
        const toggleSpinner = () => this.toggleSpinner();
        const enableSaveButton = function () {
            this.disabled = false;
        }.bind(event.target);

        return { toggleSpinner, enableSaveButton };
    }

    isFormValid(sectionsList) {
        // custom donor type validation
        const dataImportHelper = this.getDataImportHelper();
        this.resetDonorTypeValidations(sectionsList);
        if (this.isDonorTypeInvalid(dataImportHelper, sectionsList)) {
            this.displayDonorTypeError(dataImportHelper, sectionsList);
            return false;
        }

        // field validations
        const invalidFields = [];
        sectionsList.forEach((section) => {
            const fields = section.getInvalidFields();
            invalidFields.push(...fields);
        });

        if (invalidFields.length > 0) {
            const fieldListAsString = invalidFields.join(", ");
            this._hasPageLevelError = true;
            this._pageLevelErrorMessageList = [
                {
                    index: 0,
                    errorMessage: `The following fields are required: ${fieldListAsString}`,
                },
            ];
        }

        return invalidFields.length === 0;
    }

    /**
     * validates donation donor type on sectionsList
     * @param {*} dataImportHelper
     * @param {*} sectionsList, list of sections
     * @returns {boolean|*} - true if form invalid, false otherwise
     */
    isDonorTypeInvalid(dataImportHelper) {
        // if no donation donor selection, nothing to validate here yet
        if (isEmpty(this.getFieldValueFromFormState(DONATION_DONOR_FIELDS.donationDonorField))) {
            return false;
        }

        const isAccountDonor = dataImportHelper.donationDonorValue === DONATION_DONOR.isAccount1;
        const areEmptyAccountFields = dataImportHelper.isAccount1ImportedEmpty && dataImportHelper.isAccount1NameEmpty;
        const isContactDonor = dataImportHelper.donationDonorValue === DONATION_DONOR.isContact1;
        const areEmptyContactFields =
            dataImportHelper.isContact1ImportedEmpty && dataImportHelper.isContact1LastNameEmpty;
        // donation donor validation depending on selection and field presence
        return isAccountDonor
            ? areEmptyAccountFields || this._isInvalidDonorSelected
            : isContactDonor && areEmptyContactFields;
    }

    resetDonorTypeValidations(sectionsList) {
        sectionsList.forEach((section) => {
            section.setCustomValidityOnFields(Object.values(DONATION_DONOR_FIELDS), "");
        });
    }

    displayDonorTypeError(dataImportHelper, sectionsList) {
        // highlight validation fields
        this.highlightValidationErrorFields(dataImportHelper, sectionsList, " ");
        // set page error
        this._hasPageLevelError = true;
        this._pageLevelErrorMessageList = [
            {
                index: 0,
                errorMessage: this.getDonationDonorErrorLabel(dataImportHelper),
            },
        ];
    }

    /**
     * Set donation donor error message using custom label depending on field presence
     * @param {*} dataImportHelper, Object - helper obj
     * @param {*} fieldWrapper, Array of fields with Values and Labels
     * @returns {String}, formatted error message for donation donor validation
     */
    getDonationDonorErrorLabel(dataImportHelper) {
        if (this._isInvalidDonorSelected) {
            return accountDonorSelectionMismatch;
        }
        // init array replacement for custom label
        const validationErrorLabelReplacements = [
            dataImportHelper.donationDonorValue,
            dataImportHelper.donationDonorLabel,
        ];

        if (dataImportHelper.donationDonorValue === DONATION_DONOR.isAccount1) {
            if (dataImportHelper.isAccount1ImportedPresent) {
                validationErrorLabelReplacements.push(
                    GeFormService.getFieldLabelByDevNameFromTemplate(DONATION_DONOR_FIELDS.account1ImportedField)
                );
            }
            if (dataImportHelper.isAccount1NamePresent) {
                validationErrorLabelReplacements.push(
                    GeFormService.getFieldLabelBySourceFromTemplate(DONATION_DONOR_FIELDS.account1NameField)
                );
            }
        } else {
            if (dataImportHelper.isContact1ImportedPresent) {
                validationErrorLabelReplacements.push(
                    GeFormService.getFieldLabelByDevNameFromTemplate(DONATION_DONOR_FIELDS.contact1ImportedField)
                );
            }
            if (dataImportHelper.isContact1LastNamePresent) {
                validationErrorLabelReplacements.push(
                    GeFormService.getFieldLabelBySourceFromTemplate(DONATION_DONOR_FIELDS.contact1LastNameField)
                );
            }
        }

        // set label depending fields present on template
        let label;
        switch (validationErrorLabelReplacements.length) {
            case 2:
                label = this.CUSTOM_LABELS.geErrorDonorTypeInvalid;
                break;
            case 3:
                label = this.CUSTOM_LABELS.geErrorDonorTypeValidationSingle;
                break;
            case 4:
                label = this.CUSTOM_LABELS.geErrorDonorTypeValidation;
                break;
            default:
                label = this.CUSTOM_LABELS.geErrorDonorTypeInvalid;
        }

        // set message using replacement array
        return format(label, validationErrorLabelReplacements);
    }

    /**
     * highlight geForm fields on lSections using sError as message
     * @param {*} dataImportHelper, Object - helper obj
     * @param {*} lSections, Array of geFormSection
     * @param {*} sError, String to set on setCustomValidity
     */
    highlightValidationErrorFields(dataImportHelper, lSections, sError) {
        const accountFields = [DONATION_DONOR_FIELDS.account1ImportedField, DONATION_DONOR_FIELDS.account1NameField];
        const contactFields = [
            DONATION_DONOR_FIELDS.contact1ImportedField,
            DONATION_DONOR_FIELDS.contact1LastNameField,
        ];

        // prepare arrays to highlight/clear fields that require attention depending on Donation_Donor
        const highlightFields = [
            DONATION_DONOR_FIELDS.donationDonorField,
            ...(dataImportHelper.donationDonorValue === DONATION_DONOR.isAccount1 ? accountFields : contactFields),
        ];
        const clearFields =
            dataImportHelper.donationDonorValue !== DONATION_DONOR.isAccount1 ? accountFields : contactFields;

        // prepare array to highlight fields that require attention depending on Donation_Donor

        lSections.forEach((section) => {
            section.setCustomValidityOnFields(clearFields, "");
            section.setCustomValidityOnFields(highlightFields, sError);
        });
    }

    /**
     * helper object to minimize length of if statements and improve code legibility
     * @param {*} fieldWrapper, Array of fields with Values and Labels
     * @returns Object, helper object to minimize length of if statements and improve code legibility
     */
    getDataImportHelper() {
        const account1Imported = this.getFieldValueFromFormState(DONATION_DONOR_FIELDS.account1ImportedField);
        const contact1Imported = this.getFieldValueFromFormState(DONATION_DONOR_FIELDS.contact1ImportedField);
        const contact1LastName = this.getFieldValueFromFormState(DONATION_DONOR_FIELDS.contact1LastNameField);
        const account1Name = this.getFieldValueFromFormState(DONATION_DONOR_FIELDS.account1NameField);
        const isAccount1ImportedPresent = !!GeFormService.findElementByDeveloperName(
            DONATION_DONOR_FIELDS.account1ImportedField
        );
        const isAccount1NamePresent = GeFormService.isSourceFieldInTemplate(DONATION_DONOR_FIELDS.account1NameField);
        const isContact1ImportedPresent = !!GeFormService.findElementByDeveloperName(
            DONATION_DONOR_FIELDS.contact1ImportedField
        );
        const isContact1LastNamePresent = GeFormService.isSourceFieldInTemplate(
            DONATION_DONOR_FIELDS.contact1LastNameField
        );

        return {
            donationDonorValue: this.getFieldValueFromFormState(DONATION_DONOR_FIELDS.donationDonorField),
            donationDonorLabel: GeFormService.getFieldLabelBySourceFromTemplate(
                DONATION_DONOR_FIELDS.donationDonorField
            ),
            isAccount1ImportedEmpty: isEmpty(account1Imported),
            isContact1ImportedEmpty: isEmpty(contact1Imported),
            isContact1LastNameEmpty: isEmpty(contact1LastName),
            isAccount1NameEmpty: isEmpty(account1Name),
            isAccount1ImportedPresent,
            isAccount1NamePresent,
            isContact1ImportedPresent,
            isContact1LastNamePresent,
        };
    }

    // change showSpinner to the opposite of its current value
    toggleSpinner() {
        this._showSpinner = !this._showSpinner;
    }

    getDisplayedFieldsMappedByAPIName(sectionsList) {
        let allFields = {};
        sectionsList.forEach((section) => {
            const fields = section.getAllFieldsByAPIName();

            allFields = Object.assign(allFields, fields);
        });

        return allFields;
    }

    clearErrors() {
        // Clear the page level error
        this._hasPageLevelError = false;
        this._pageLevelErrorMessageList = [];

        // Clear the field level custom validations
        const sections = this.template.querySelectorAll("c-ge-form-section");
        sections.forEach((section) => {
            const fields = section.getAllFieldsByAPIName();
            Object.values(fields).forEach((field) => {
                field.clearCustomValidity();
            });
        });

        // Clear the field level errors from custom aura exception
        if (this.erroredFields.length > 0) {
            this.erroredFields.forEach((fieldToReset) => {
                fieldToReset.setCustomValidity("");
            });
        }

        this.erroredFields = [];
    }

    reset() {
        this.clearErrors();
        this.resetFormState();
        this._openedGiftId = null;
    }

    resetFormState() {
        fireEvent(this, "resetReviewDonationsEvent", {});
        this.initializeFormState();
    }

    resetFieldsForObjMappingApplyDefaults(objectMappingDeveloperName) {
        this.setFormStateToInitialFieldValuesForObjMapping(objectMappingDeveloperName);
    }

    get mode() {
        return this.getFieldValueFromFormState("Id") ? mode.UPDATE : mode.CREATE;
    }

    get saveActionLabel() {
        return this.isSingleGiftEntry
            ? this.CUSTOM_LABELS.commonSave
            : this.mode === mode.UPDATE
              ? this.CUSTOM_LABELS.commonUpdate
              : this.CUSTOM_LABELS.geButtonSaveNewGift;
    }

    get isUpdateActionDisabled() {
        return (
            this.getFieldValueFromFormState(STATUS_FIELD) === GIFT_STATUSES.IMPORTED ||
            this.saveDisabled
        );
    }

    handleFormWidgetChange = (event) => {
        this.updateFormState(event.detail);
    };

    /*******************************************************************************
     * @description Pass through method that receives an event from geReviewDonations
     * to notify the parent component to construct a modal for reviewing donations.
     *
     * @param {object} event: Event object containing a payload for the modal.
     */
    toggleModal(event) {
        this.dispatchEvent(new CustomEvent("togglemodal", { detail: event.detail }));
    }

    getSiblingFieldsForSourceField(sourceFieldApiName) {
        const objectMapping = Object.values(GeFormService.objectMappings).find(
            ({ Imported_Record_Field_Name }) => Imported_Record_Field_Name === sourceFieldApiName
        );
        return this.getSiblingFields(objectMapping.DeveloperName);
    }

    getSiblingFields(objectMappingDeveloperName) {
        // For a given field, get the full list of fields related to its object mapping

        // 1. Get this field's object mapping
        // 2. Get the other field mappings that have the same Target_Object_Mapping_Dev_Name
        // 3. Return the list of fields from those mappings

        const objectMapping = GeFormService.getObjectMapping(objectMappingDeveloperName);

        const relevantFieldMappings = Object.values(GeFormService.fieldMappings).filter(
            ({ Target_Object_Mapping_Dev_Name }) => Target_Object_Mapping_Dev_Name === objectMapping.DeveloperName
        );

        // Return the sibling fields used by Advanced Mapping
        const relevantFields = relevantFieldMappings.map(
            ({ Target_Field_API_Name }) => `${objectMapping.Object_API_Name}.${Target_Field_API_Name}`
        );

        if (this.isPaymentImportedField(objectMapping.Imported_Record_Field_Name)) {
            const pmtAmountField = `${objectMapping.Object_API_Name}.${apiNameFor(OPP_PAYMENT_AMOUNT)}`;
            const pmtScheduledDate = `${objectMapping.Object_API_Name}.${apiNameFor(SCHEDULED_DATE)}`;
            relevantFields.push(pmtAmountField, pmtScheduledDate);
        }
        return relevantFields;
    }

    objectMappingDeveloperNameFor(fieldApiName) {
        const objectMapping = this.getObjectMapping(fieldApiName);
        return objectMapping && objectMapping.DeveloperName;
    }

    @track selectedDonationCopyForReviewDonationsModal;
    handleChangeSelectedDonation(event) {
        this.selectedDonationCopyForReviewDonationsModal = event.detail.payment || event.detail.opportunity;

        this.selectedDonationOrPaymentRecord = this.selectedDonationCopyForReviewDonationsModal;
        if (!this.isSingleGiftEntry) {
            this.expandForm();
        }
    }

    hasSelectedDonationOrPayment() {
        return !!this.selectedDonationOrPaymentRecordId();
    }

    setCreateNewOpportunityInFormState() {
        this.resetDonationAndPaymentImportedFields();
        this.updateFormState({
            [apiNameFor(DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD)]: userSelectedNewOpp,
        });
    }

    resetDonationAndPaymentImportedFields() {
        this.resetSelectedPaymentFieldsInFormState();
        this.resetSelectedDonationFieldsInFormState();
    }

    /**
     * @description Function that prepares (sets batch defaults, remove credit card widget)
     * the gift entry form in Batch Mode
     * @param {*} templateSections
     * @returns {sections}
     */
    prepareFormForBatchMode(templateSections) {
        const sections = deepClone(templateSections);
        const batchDefaults = this._batch[apiNameFor(BATCH_DEFAULTS_FIELD)];
        if (isNotEmpty(batchDefaults)) {
            let batchDefaultsObject;
            try {
                batchDefaultsObject = JSON.parse(batchDefaults);
                sections.forEach((section) => {
                    section.elements.forEach((element) => {
                        for (const key in batchDefaultsObject) {
                            if (
                                Object.prototype.hasOwnProperty.call(batchDefaultsObject, key) &&
                                key === element.customLabel
                            ) {
                                const batchDefault = batchDefaultsObject[key];
                                if (
                                    batchDefault.objectApiName === element.objectApiName &&
                                    batchDefault.fieldApiName === element.fieldApiName
                                ) {
                                    if (!isUndefined(batchDefault.value)) {
                                        element.defaultValue = batchDefault.value;
                                    }
                                }
                            }
                        }
                    });
                });
            } catch (err) {
                handleError(err);
            }
        }
        return sections;
    }

    /**
     * @description Retrieves a records mapped target field values and
     *              loads them into the appropriate source fields in use
     *              on the Gift Entry form.
     * @param {*} lookupFieldApiName Api name of the lookup field.
     * @param {*} selectedRecordId Id of the selected record.
     */
    loadSelectedRecordFieldValues(lookupFieldApiName, selectedRecordId) {
        const selectedRecordFields = this.getSiblingFieldsForSourceField(lookupFieldApiName);

        this.storeSelectedRecordIdByObjectMappingName(
            this.getObjectMapping(lookupFieldApiName).DeveloperName,
            selectedRecordId
        );

        this.lookupFieldApiNameBySelectedRecordId[selectedRecordId] = lookupFieldApiName;
        this.queueSelectedRecordForRetrieval(selectedRecordId, selectedRecordFields);
    }

    lookupFieldApiNameBySelectedRecordId = {};

    get oppPaymentKeyPrefix() {
        return this.oppPaymentObjectInfo.data.keyPrefix;
    }

    isAnOpportunityId(id) {
        if (!id || typeof id !== "string") {
            return false;
        }
        return id.startsWith(this.opportunityKeyPrefix);
    }

    isAPaymentId(id) {
        if (!id || typeof id !== "string") {
            return false;
        }
        return id.startsWith(this.oppPaymentKeyPrefix);
    }

    get opportunityKeyPrefix() {
        return this.opportunityObjectInfo.data.keyPrefix;
    }

    get accountKeyPrefix() {
        return this.accountObjectInfo.data.keyPrefix;
    }

    get contactKeyPrefix() {
        return this.contactObjectInfo.data.keyPrefix;
    }

    getObjectMapping(fieldApiName) {
        return Object.values(GeFormService.objectMappings).find(
            ({ Imported_Record_Field_Name }) => Imported_Record_Field_Name === fieldApiName
        );
    }

    // Properties used to manage retrieval of fields for selected records
    selectedRecordIdByObjectMappingDevName = {};
    selectedRecordId;
    selectedRecordFields;
    getSelectedRecordStatus = "ready";
    selectedRecordsQueue = [];

    @wire(getRecord, { recordId: "$selectedRecordId", optionalFields: "$selectedRecordFields" })
    getSelectedRecord({ error, data }) {
        if (error) {
            handleError(error);
        } else if (data) {
            const updates = this.getFormStateUpdatesFromSelectedRecord(data);
            this.updateFormState(updates);
        }
        this.loadNextSelectedRecordFromQueue();
    }

    loadNextSelectedRecordFromQueue() {
        if (this.selectedRecordsQueue.length > 0) {
            const nextSelectedRecord = this.selectedRecordsQueue.pop();
            this.selectedRecordId = nextSelectedRecord.selectedRecordId;
            this.selectedRecordFields = nextSelectedRecord.selectedRecordFields;
        } else {
            // If there are no records in the queue, set status back to 'ready'
            this.getSelectedRecordStatus = "ready";
        }
    }

    @wire(getObjectInfo, { objectApiName: OPP_PAYMENT_OBJECT })
    oppPaymentObjectInfo;

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    opportunityObjectInfo;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountObjectInfo;

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    contactObjectInfo;

    @wire(getObjectInfo, { objectApiName: DATA_IMPORT_OBJECT })
    dataImportObjectInfo;

    mapRecordValuesToDataImportFields(record) {
        //reverse map to create an object with relevant source field api names to values
        let dataImport = {};
        const objectMappingDevNames = this.getObjectMappingDevNamesForSelectedRecord(record);

        objectMappingDevNames.forEach((objectMappingName) => {
            this.fieldMappingsFor(objectMappingName).forEach((fieldMapping) => {
                const valueObjectFromRecord = record.fields[fieldMapping.Target_Field_API_Name];
                const sourceField = fieldMapping.Source_Field_API_Name;

                if (this.isFieldMappingUsedInTemplate(fieldMapping)) {
                    dataImport[sourceField] = this.getFieldValueForFormState(valueObjectFromRecord, fieldMapping);
                }
            });

            const objectMapping = GeFormService.getObjectMapping(objectMappingName);
            if (this.isPaymentImportedObjectMapping(objectMapping)) {
                dataImport = this.overwriteDonationAmountAndDateWithPaymentInfo(dataImport, record);
            }
        });

        return dataImport;
    }

    isFieldMappingUsedInTemplate(fieldMapping) {
        return this.fieldMappingDevNamesUsedInTemplate().includes(fieldMapping.DeveloperName);
    }

    getFieldValueForFormState(valueObject, fieldMapping) {
        const { value } = valueObject;

        if (value === null) {
            return this.defaultValueFor(fieldMapping.DeveloperName);
        } else if (isTrueFalsePicklist(fieldMapping)) {
            return this.transformForTrueFalsePicklist(value);
        }

        return value;
    }

    isPaymentImportedObjectMapping(objectMapping) {
        return (
            objectMapping && objectMapping.Imported_Record_Field_Name === apiNameFor(DATA_IMPORT_PAYMENT_IMPORTED_FIELD)
        );
    }

    overwriteDonationAmountAndDateWithPaymentInfo(dataImport, record) {
        dataImport[apiNameFor(DATA_IMPORT_DONATION_AMOUNT)] = record.fields[apiNameFor(OPP_PAYMENT_AMOUNT)].value;
        dataImport[apiNameFor(DATA_IMPORT_DONATION_DATE)] = record.fields[apiNameFor(SCHEDULED_DATE)].value;
        return dataImport;
    }

    getObjectMappingDevNamesForSelectedRecord(record) {
        const objectMappingDevNames = [];
        for (const [key, value] of Object.entries(this.selectedRecordIdByObjectMappingDevName)) {
            if (value === record.id) {
                objectMappingDevNames.push(key);
            }
        }
        return objectMappingDevNames;
    }

    storeSelectedRecordIdByObjectMappingName(objectMappingName, recordId) {
        this.selectedRecordIdByObjectMappingDevName[objectMappingName] = recordId;
    }

    set donorId(id) {
        this.updateFormStateFromMap(new Map([[this.lookupFieldForDonorId(id), id]]));
    }

    lookupFieldForDonorId(id) {
        return this.isAnAccountId(id)
            ? DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD
            : this.isAContactId(id)
              ? DATA_IMPORT_CONTACT1_IMPORTED_FIELD
              : null;
    }

    get donorId() {
        switch (this.donorType) {
            case DONATION_DONOR_TYPE_ENUM.ACCOUNT1:
                return this.getFieldValueFromFormState(DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD);
            case DONATION_DONOR_TYPE_ENUM.CONTACT1:
                return this.getFieldValueFromFormState(DATA_IMPORT_CONTACT1_IMPORTED_FIELD);
            default:
                return null;
        }
    }

    handleDonationDonorChange() {
        this._isInvalidDonorSelected = false;
        if (this.hasSelectedDonationOrPayment()) {
            this.resetDonationAndPaymentImportedFields();
            fireEvent(this, "resetReviewDonationsEvent", {});
        }
    }

    /**
     * @description Queues selected record Ids (and fields) when getRecord is
     *              in the progress of retrieving another record's related fields.
     *              Prevents one lookup from overwriting the reactive selectedRecordId
     *              and selectedRecordFields properties before getRecord has returned
     *              with data.
     * @param {*} selectedRecordId Id of record to be retrieved.
     * @param {*} selectedRecordFields Fields list to be retrieved.
     */
    queueSelectedRecordForRetrieval(selectedRecordId, selectedRecordFields) {
        if (this.getSelectedRecordStatus === "ready") {
            this.getSelectedRecordStatus = "pending";
            this.selectedRecordId = selectedRecordId;
            this.selectedRecordFields = selectedRecordFields;
        } else {
            this.selectedRecordsQueue.push({ selectedRecordId, selectedRecordFields });
        }
    }

    // ================================================================================
    // AUTOMATION LOCATOR GETTERS
    // ================================================================================

    get qaLocatorCancelButton() {
        return `button ${this.cancelButtonText}`;
    }

    get qaLocatorSaveButton() {
        return `button ${this.saveActionLabel}`;
    }

    @api
    get giftInView() {
        return this._giftInView;
    }

    set giftInView(gift) {
        if (!this._connected) {
            return;
        }

        if (gift && isEmptyObject(gift.fields)) {
            this.reset();
        } else if (gift && gift.fields) {
            const giftLocalCopy = deepClone(gift);
            this.handleWidgetJSON(giftLocalCopy.fields);
            this._giftInView = giftLocalCopy;
            this._openedGiftId = giftLocalCopy.fields.Id || null;
            this.formState = giftLocalCopy.fields;

            if (this._openedGiftId && this.hasPageLevelError && this.batchId) {
                this.clearErrors();
            }
        }
    }

    handleWidgetJSON(giftFields) {
        if (giftFields[apiNameFor(DATA_IMPORT_ADDITIONAL_OBJECT_FIELD)]) {
            giftFields[apiNameFor(DATA_IMPORT_ADDITIONAL_OBJECT_FIELD)] = convertBDIToWidgetJson(
                giftFields[apiNameFor(DATA_IMPORT_ADDITIONAL_OBJECT_FIELD)]
            );
        }
    }

    get formState() {
        return this._formState;
    }

    set formState(formState) {
        this._formState = formState;
    }

    lookupFieldApiNameFor(recordId) {
        const valueForKeyByStartsWith = this.getValueForKeyByStartsWith(
            recordId,
            this.lookupFieldApiNameBySelectedRecordId
        );

        return this.lookupFieldApiNameBySelectedRecordId[recordId] || valueForKeyByStartsWith;
    }

    /*******************************************************************************
     * @description Updates the formState object that holds the current value
     * of all fields on the form.
     * @param {*} fields An object with key-value pairs.
     */
    updateFormState(fields) {
        fields = this.removeFieldsNotUpdatableInFormState(fields);

        if (this.hasSchedule) {
            fields = this.syncDonationFormStateFieldsToRDFields(fields);
        }

        if (Object.prototype.hasOwnProperty.call(fields, apiNameFor(DATA_IMPORT_DONATION_RECORD_TYPE_NAME))) {
            fields = this.updateFormStateForDonationRecordType(fields);
        }

        if (this.hasImportedRecordFieldsBeingSetToNull(fields)) {
            this.deleteRelationshipFieldsFromStateFor(fields);
        }

        const formStateChangeEvent = new CustomEvent("formstatechange", { detail: deepClone(fields) });
        this.dispatchEvent(formStateChangeEvent);
    }

    syncDonationFormStateFieldsToRDFields(fields) {
        if (Object.prototype.hasOwnProperty.call(fields, apiNameFor(DATA_IMPORT_DONATION_AMOUNT))) {
            fields[apiNameFor(DATA_IMPORT_RECURRING_DONATION_RECURRING_AMOUNT)] =
                fields[apiNameFor(DATA_IMPORT_DONATION_AMOUNT)];
        }

        if (Object.prototype.hasOwnProperty.call(fields, apiNameFor(DATA_IMPORT_DONATION_DATE))) {
            fields[apiNameFor(DATA_IMPORT_RECURRING_DONATION_DATE_ESTABLISHED)] =
                fields[apiNameFor(DATA_IMPORT_DONATION_DATE)];
        }

        if (Object.prototype.hasOwnProperty.call(fields, apiNameFor(PAYMENT_METHOD))) {
            fields[apiNameFor(DATA_IMPORT_RECURRING_DONATION_PAYMENT_METHOD)] = fields[apiNameFor(PAYMENT_METHOD)];
        }
        return fields;
    }

    removeFieldsNotUpdatableInFormState(fieldsToUpdate) {
        FORM_STATE_IMMUTABLE_FIELDS_API_NAMES.forEach((immutableField) => {
            if (this.isFormStateFieldNotUpdatable(fieldsToUpdate, immutableField)) {
                delete fieldsToUpdate[immutableField];
            }
        });

        return fieldsToUpdate;
    }

    isFormStateFieldNotUpdatable(fields, field) {
        return Object.prototype.hasOwnProperty.call(fields, field) && this.formState[field];
    }

    updateFormStateFromMap(fieldReferenceToValueMap) {
        const updates = {};
        for (const [key, value] of fieldReferenceToValueMap.entries()) {
            if (typeof key === "string" || key instanceof String) {
                updates[key] = value;
            } else {
                updates[apiNameFor(key)] = value;
            }
        }
        this.updateFormState(updates);
    }

    updateFormStateForDonationRecordType(fields) {
        const opportunityRecordTypeValue = fields[apiNameFor(DATA_IMPORT_DONATION_RECORD_TYPE_NAME)];

        if (opportunityRecordTypeValue) {
            const isId = opportunityRecordTypeValue.startsWith("012");
            const val = isId ? opportunityRecordTypeValue : this.opportunityRecordTypeIdFor(opportunityRecordTypeValue);

            if (isId) {
                fields = {
                    ...fields,
                    [apiNameFor(DATA_IMPORT_DONATION_RECORD_TYPE_NAME)]: this.opportunityRecordTypeNameFor(val),
                };
            }

            this.setDonationRecordTypeIdInFormState(val);
        }

        return fields;
    }

    opportunityRecordTypeNameFor(id) {
        const found =
            this.opportunityRecordTypeInfos &&
            this.opportunityRecordTypeInfos.find((recordTypeInfo) => recordTypeInfo.recordTypeId === id);

        return found && found.name;
    }

    hasImportedRecordFieldsBeingSetToNull(fields) {
        return (
            Object.keys(fields).filter(
                (field) => GeFormService.importedRecordFieldNames.includes(field) && fields[field] === null
            ).length > 0
        );
    }

    deleteRelationshipFieldsFromStateFor(fields) {
        const needsRelationshipFieldDeleted = (field) =>
            this.hasRelatedRecordFieldInFormState(field) && fields[field] === null;

        Object.keys(fields)
            .filter(needsRelationshipFieldDeleted)
            .forEach((field) => {
                this.deleteFieldFromFormState(relatedRecordFieldNameFor(field));
            });
    }

    deleteFieldFromFormState(field) {
        const deleteFieldFromGiftState = new CustomEvent("deletefieldfromgiftstate", {
            detail: field,
        });
        this.dispatchEvent(deleteFieldFromGiftState);
    }

    hasRelatedRecordFieldInFormState(field) {
        return Object.prototype.hasOwnProperty.call(this.formState, relatedRecordFieldNameFor(field));
    }

    handleFormFieldChange(event) {
        const value = event.detail.value,
            label = event.detail.label,
            sourceField = this.sourceFieldFor(event.detail.fieldMappingDevName),
            isDonationRecordTypeName = this.isDonationRecordTypeName(sourceField),
            isDonationDonor = this.isDonationDonor(sourceField),
            isImportedRecordField = this.isImportedRecordField(sourceField);

        this.updateFormState({
            [sourceField]: isDonationRecordTypeName ? label : value,
        });

        if (isDonationRecordTypeName) {
            this.setDonationRecordTypeIdInFormState(value);
        }

        if (isDonationDonor) {
            this.handleDonationDonorChange(value);
            fireEvent(this, "clearprocessedsoftcreditsinview", {});
        }

        if (isImportedRecordField) {
            this.handleImportedRecordFieldChange(sourceField, value);
            fireEvent(this, "clearprocessedsoftcreditsinview", {});
        }
    }

    isDonationDonor(fieldApiName) {
        return fieldApiName === apiNameFor(DATA_IMPORT_DONATION_DONOR_FIELD);
    }

    isDonationRecordTypeName(fieldApiName) {
        return fieldApiName === apiNameFor(DATA_IMPORT_DONATION_RECORD_TYPE_NAME);
    }

    handleImportedRecordFieldChange(sourceField, value) {
        this.populateRelatedFieldsForSelectedLookupRecord(sourceField, value);
    }

    populateRelatedFieldsForSelectedLookupRecord(sourceField, value) {
        if (value) {
            this.loadSelectedRecordFieldValues(sourceField, value);
        } else {
            this.resetFieldsForObjMappingApplyDefaults(this.objectMappingDeveloperNameFor(sourceField));
        }
    }

    sourceFieldFor(fieldMappingDevName) {
        return GeFormService.getFieldMappingWrapper(fieldMappingDevName).Source_Field_API_Name;
    }

    /*******************************************************************************
     * @description Analyzes the sections property to get initial values and set them
     * in the formState property.
     */
    initializeFormState() {
        this.formState = {};
        if (this.sections) {
            this.sections.forEach((section) => {
                if (section.elements) {
                    section.elements.forEach((element) => {
                        this.setInitialValueInFormStateForElement(element);
                    });
                }
            });
        }

        if (this.batchId) {
            this.updateFormState({
                [apiNameFor(NPSP_DATA_IMPORT_BATCH_FIELD)]: this.batchId,
            });
        }

        this.setFormStateForURLQueryParameters();
    }

    setFormStateForURLQueryParameters() {
        const donorApiName = getQueryParameters().c__apiName;
        const donorId = getQueryParameters().c__donorRecordId;

        if (donorApiName) {
            this.initializeDonationDonorTypeInFormState(donorApiName);
        }
        if (donorId) {
            this.donorId = donorId;
        }
    }

    setInitialValueInFormStateForElement(element) {
        const sourceField = this.getSourceFieldApiNameFor(element);
        const value = this.getValueFrom(element);
        const isLookupWithDefaultValue = value && GeFormService.importedRecordFieldNames.includes(sourceField);

        this.updateFormState({ [sourceField]: value });

        if (isLookupWithDefaultValue) {
            this.loadSelectedRecordFieldValues(sourceField, value);
        }
    }

    setInitialValueInFormStateForFieldMappings(fieldMappingDevNames) {
        this.resetFieldsToNullInFormStateIfPresent(fieldMappingDevNames);

        this.elementsFor(fieldMappingDevNames).forEach((el) => this.setInitialValueInFormStateForElement(el));
    }

    resetFieldsToNullInFormStateIfPresent(fieldMappingDevNames) {
        const updates = {};
        fieldMappingDevNames.forEach((fieldMappingDevName) => {
            const sourceField = this.sourceFieldFor(fieldMappingDevName);
            if (Object.prototype.hasOwnProperty.call(this.formState, sourceField)) {
                updates[sourceField] = null;
            }
        });
        this.updateFormState(updates);
    }

    elementsFor(fieldMappingDevNames) {
        const foundInFieldMappingDevNames = (fieldMappingDevName) => fieldMappingDevNames.includes(fieldMappingDevName);

        return this.sections
            .map((s) => s.elements)
            .flat()
            .filter((element) => element.dataImportFieldMappingDevNames.some(foundInFieldMappingDevNames));
    }

    setFormStateToInitialFieldValuesForObjMapping(objectMappingDeveloperName) {
        this.setInitialValueInFormStateForFieldMappings(
            this.fieldMappingsFor(objectMappingDeveloperName).map(({ DeveloperName }) => DeveloperName)
        );
    }

    fieldMappingsFor(objectMappingDeveloperName) {
        return GeFormService.fieldMappingsForObjectMappingDevName(objectMappingDeveloperName);
    }

    getSourceFieldApiNameFor(element) {
        return this.fieldMappingWrapperFor(element) && this.fieldMappingWrapperFor(element).Source_Field_API_Name;
    }

    fieldMappingWrapperFor(element) {
        return (
            element.dataImportFieldMappingDevNames &&
            GeFormService.getFieldMappingWrapper(element.dataImportFieldMappingDevNames[0])
        );
    }

    getValueFrom(element) {
        return element && element.recordValue !== undefined ? element.recordValue : element.defaultValue;
    }

    opportunityRecordTypeIdFor(opportunityRecordTypeName) {
        const recordTypeInfo = Object.values(this.opportunityRecordTypeInfos).find(
            (rtInfo) => rtInfo.name === opportunityRecordTypeName
        );

        if (!recordTypeInfo) {
            return null;
        }
        return recordTypeInfo.recordTypeId;
    }

    get opportunityRecordTypeInfos() {
        return this.opportunityObjectInfo && Object.values(this.opportunityObjectInfo.data.recordTypeInfos);
    }

    transformForTrueFalsePicklist(value) {
        if (value === true || value === CHECKBOX_TRUE) {
            return PICKLIST_TRUE;
        } else if (value === false || value === CHECKBOX_FALSE) {
            return PICKLIST_FALSE;
        }
        return ""; // blank values are valid for picklist/checkbox mappings
    }

    setDonationRecordTypeIdInFormState(opportunityRecordTypeId) {
        const donationImportedRelatedRecordField = relatedRecordFieldNameFor(
            apiNameFor(DATA_IMPORT_DONATION_IMPORTED_FIELD)
        );
        const relatedRecord = this.getFieldValueFromFormState(donationImportedRelatedRecordField);

        let updatedRecord;
        if (relatedRecord) {
            updatedRecord = Object.assign(deepClone(relatedRecord), { recordTypeId: opportunityRecordTypeId });
        } else {
            updatedRecord = { recordTypeId: opportunityRecordTypeId };
        }

        this.updateFormState({
            [donationImportedRelatedRecordField]: updatedRecord,
        });
    }

    siblingRecordTypeFieldFor(fieldMappingDevName) {
        const fieldMappingToRecordTypeId = Object.values(GeFormService.fieldMappings)
            .filter((f) => f.Target_Object_Mapping_Dev_Name === this.objectMappingDevNameFor(fieldMappingDevName))
            .find((f) => f.Target_Field_API_Name === "RecordTypeId");

        return fieldMappingToRecordTypeId && fieldMappingToRecordTypeId.Source_Field_API_Name;
    }

    objectMappingDevNameFor(fieldMappingDevName) {
        const fieldMapping = GeFormService.getFieldMappingWrapper(fieldMappingDevName);
        return fieldMapping && fieldMapping.Target_Object_Mapping_Dev_Name;
    }

    parentRecordFieldFor(fieldMappingDevName) {
        const objMapping = GeFormService.getObjectMapping(this.objectMappingDevNameFor(fieldMappingDevName));

        return objMapping && objMapping.Imported_Record_Field_Name;
    }

    get donorType() {
        return this.getFieldValueFromFormState(apiNameFor(DATA_IMPORT_DONATION_DONOR_FIELD));
    }

    /**
     * @description Pass in a DataImport field's api to get that field's current
     * value from the formState object.
     * @param {*} fieldApiNameOrFieldReference: field name or an imported field reference object
     * @returns {*} Current value stored in formState for the passed-in field.
     */
    getFieldValueFromFormState(fieldApiNameOrFieldReference) {
        const fieldApiName =
            typeof fieldApiNameOrFieldReference === "string"
                ? fieldApiNameOrFieldReference
                : apiNameFor(fieldApiNameOrFieldReference);

        return this.formState[fieldApiName];
    }

    defaultValueFor(fieldMappingDevName) {
        const element = this.formElements().find((el) => el.dataImportFieldMappingDevNames[0] === fieldMappingDevName);

        return element && element.defaultValue;
    }

    fieldMappingDevNamesUsedInTemplate() {
        return this.formElements()
            .filter((element) => element.elementType === "field")
            .map((element) => element.dataImportFieldMappingDevNames[0]);
    }

    formElements() {
        return this.sections
            .flat()
            .map(({ elements }) => elements)
            .flat();
    }

    isImportedRecordField(fieldApiName) {
        return GeFormService.importedRecordFieldNames.includes(fieldApiName);
    }

    isDonorTypeAccount() {
        return this.donorType === DONATION_DONOR_TYPE_ENUM.ACCOUNT1;
    }

    selectedDonationOrPaymentRecordId() {
        return (
            this.getFieldValueFromFormState(DATA_IMPORT_PAYMENT_IMPORTED_FIELD) ||
            this.getFieldValueFromFormState(DATA_IMPORT_DONATION_IMPORTED_FIELD)
        );
    }

    resetSelectedPaymentFieldsInFormState() {
        this.updateFormState({
            [apiNameFor(DATA_IMPORT_PAYMENT_IMPORTED_FIELD)]: null,
            [apiNameFor(DATA_IMPORT_PAYMENT_IMPORT_STATUS_FIELD)]: null,
            [relatedRecordFieldNameFor(apiNameFor(DATA_IMPORT_PAYMENT_IMPORTED_FIELD))]: null,
        });

        this.resetFieldsForObjMappingApplyDefaults(
            this.objectMappingDeveloperNameForFieldReference(DATA_IMPORT_PAYMENT_IMPORTED_FIELD)
        );
    }

    resetSelectedDonationFieldsInFormState() {
        const updates = new Map();
        updates.set(DATA_IMPORT_DONATION_IMPORTED_FIELD, null);
        updates.set(DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD, null);
        updates.set(relatedRecordFieldNameFor(DATA_IMPORT_DONATION_IMPORTED_FIELD), null);
        this.updateFormStateFromMap(updates);

        this.resetFieldsForObjMappingApplyDefaults(
            this.objectMappingDeveloperNameForFieldReference(DATA_IMPORT_DONATION_IMPORTED_FIELD)
        );
    }

    objectMappingDeveloperNameForFieldReference(fieldReference) {
        const objectMapping = this.getObjectMapping(apiNameFor(fieldReference));
        return objectMapping && objectMapping.DeveloperName;
    }

    saveableFormState() {
        let dataImportRecord = { ...this.formState };
        dataImportRecord = this.removeFieldsNotInObjectInfo(dataImportRecord);

        return dataImportRecord;
    }

    removeFieldsNotInObjectInfo(dataImportRecord) {
        const diFields = Object.keys(this.dataImportObjectInfo.data.fields);
        for (const key of Object.keys(dataImportRecord)) {
            if (!diFields.includes(key)) {
                delete dataImportRecord[key];
            }
        }
        return dataImportRecord;
    }

    get hasDataImportId() {
        return !!this.getFieldValueFromFormState("id"); /* @todo Possible existing bug?  Should this be "Id" instead of "id"? */
    }

    /*******************************************************************************
     * @description Saves a Data Import record and processes the Data Import through BDI.
     *
     * @param {*} dataImportFromFormState
     */
    submitSingleGift = async () => {
        const gift = this.saveableFormState();
        try {
            await this.saveDataImport(gift);
            await this.processDataImport();
        } catch (error) {
            this.disabled = false; /* @todo Possible existing bug?  There is no disabled property on this class.  What is `this` bound to when this is executed? */
            this.toggleSpinner();

            const exceptionWrapper = new ExceptionDataError(error);
            if (isNotEmpty(exceptionWrapper.exceptionType)) {
                this.handleCatchOnSave(error);
            } else {
                handleError(error);
            }
        }
    };

    saveDataImport = async (dataImportFromFormState) => {
        this._loadingText = this.hasDataImportId ? this.CUSTOM_LABELS.geTextUpdating : this.CUSTOM_LABELS.geTextSaving;
        const dataImportfieldsInfo = this.dataImportObjectInfo?.data?.fields || {};
        Object.keys(dataImportFromFormState).forEach((field) => {
            if (dataImportfieldsInfo[field]?.dataType === "Boolean" && dataImportFromFormState[field] === undefined) {
                dataImportFromFormState[field] = false;
            } else {
                dataImportFromFormState[field] ??= null;
            }
        });
        const upsertResponse = await upsertDataImport({
            dataImport: JSON.stringify(dataImportFromFormState),
        });
        this.updateFormState(upsertResponse);
    };

    processDataImport = async () => {
        const gift = new Gift(this.giftInView);

        this._loadingText = this.CUSTOM_LABELS.geTextProcessing;

        await gift.save().catch((saveError) => this.handleCatchOnSave(saveError));

        await gift.refresh().catch((viewError) => handleError(viewError));

        if (gift.isFailed()) {
            this.handleBdiProcessingError(gift.failureInformation());
        } else {
            this._loadingText = this.CUSTOM_LABELS.geTextNavigateToOpportunity;
            this.goToRecordDetailPage(gift.donationId());
        }
    };

    handleBdiProcessingError(error) {
        this.handleCatchOnSave(error);
        this.toggleSpinner();
    }

    isAnAccountId(id) {
        return id && typeof id === "string" && id.startsWith(this.accountKeyPrefix);
    }

    isAContactId(id) {
        return id && typeof id === "string" && id.startsWith(this.contactKeyPrefix);
    }

    getValueForKeyByStartsWith(longKey, keyValueMap) {
        for (const [key, value] of Object.entries(keyValueMap)) {
            if (longKey.startsWith(key)) {
                return value;
            }
        }
        return undefined;
    }

    isPaymentImportedField(sourceField) {
        return sourceField === apiNameFor(DATA_IMPORT_PAYMENT_IMPORTED_FIELD);
    }

    getFormStateUpdatesFromSelectedRecord(record) {
        const formStateUpdates = this.mapRecordValuesToDataImportFields(record);
        const relatedRecordFieldName = relatedRecordFieldNameFor(this.lookupFieldApiNameFor(record.id));
        formStateUpdates[relatedRecordFieldName] = record;
        return formStateUpdates;
    }

    @api
    get isFormCollapsed() {
        return this._isFormCollapsed;
    }

    set isFormCollapsed(value) {
        this._isFormCollapsed = value;
    }

    get altTextLabel() {
        return "Toggle " + this.CUSTOM_LABELS.geHeaderFormFieldsDefaultSectionName;
    }

    expandForm() {
        if (this.isFormCollapsed) {
            this.dispatchEvent(new CustomEvent("collapseform", { detail: false }));
        }
    }

    get expandableContainerId() {
        return EXPANDABLE_SECTION_CONTAINER;
    }

    handleCollapse(event) {
        this.dispatchEvent(new CustomEvent("collapseform", { detail: event.detail.isCollapsed }));
    }

    get showMismatchedCurrencyWarning() {
        if (isEmpty(this.batchCurrencyIsoCode)) {
            return false;
        }
        return this.batchCurrencyIsoCode !== CURRENCY;
    }

    get mismatchedCurrencyWarning() {
        if (this.showMismatchedCurrencyWarning) {
            return GeLabelService.format(this.CUSTOM_LABELS.geWarningBatchGiftEntryCurrencyMismatch, [
                this.batchCurrencyIsoCode,
            ]);
        }
        return undefined;
    }
}
