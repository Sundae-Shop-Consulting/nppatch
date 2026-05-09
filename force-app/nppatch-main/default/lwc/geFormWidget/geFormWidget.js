import { LightningElement, api, track } from "lwc";
import { apiNameFor, getSubsetObject, isEmptyObject } from "c/utilCommon";
import DATA_IMPORT_ADDITIONAL_OBJECT_JSON_FIELD from "@salesforce/schema/DataImport__c.Additional_Object_JSON__c";
import DATA_IMPORT_DONATION_AMOUNT_FIELD from "@salesforce/schema/DataImport__c.Donation_Amount__c";

const ALLOCATION_WIDGET = "geFormWidgetAllocation";
const SOFT_CREDIT_WIDGET = "geFormWidgetSoftCredit";
const WIDGET_LIST = [ALLOCATION_WIDGET, SOFT_CREDIT_WIDGET];

export default class GeFormWidget extends LightningElement {
    @api element;
    @api giftInView;

    @track widgetDataFromState = {};

    _formState = {};

    _allocationFields = [
        apiNameFor(DATA_IMPORT_DONATION_AMOUNT_FIELD),
        apiNameFor(DATA_IMPORT_ADDITIONAL_OBJECT_JSON_FIELD),
    ];

    _softCreditFields = [];

    @api
    get formState() {
        return this._formState;
    }

    set formState(formState) {
        if (isEmptyObject(formState)) {
            return;
        }

        const shouldUpdateAllocationWidgetState = this.isAllocation && this.hasAllocationValuesChanged(formState);
        if (shouldUpdateAllocationWidgetState) {
            this.sliceWidgetDataFromFormState(formState, this._allocationFields);
        }

        this._formState = Object.assign({}, formState);
    }

    sliceWidgetDataFromFormState(formState, fields) {
        this.widgetDataFromState = getSubsetObject(formState, fields);
    }

    hasAllocationValuesChanged(formState) {
        const donationFieldApiName = apiNameFor(DATA_IMPORT_DONATION_AMOUNT_FIELD);
        const additionalObjectFieldApiName = apiNameFor(DATA_IMPORT_ADDITIONAL_OBJECT_JSON_FIELD);

        return (
            formState[donationFieldApiName] !== this.formState[donationFieldApiName] ||
            formState[additionalObjectFieldApiName] !== this.formState[additionalObjectFieldApiName]
        );
    }

    get isSoftCredit() {
        return this.element.componentName === SOFT_CREDIT_WIDGET;
    }

    get isAllocation() {
        return this.element.componentName === ALLOCATION_WIDGET;
    }

    get widgetNotFound() {
        return WIDGET_LIST.indexOf(this.element.componentName) < 0;
    }
}
