import { createElement } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import GeFormRenderer from "c/geFormRenderer";
const pubSub = require("c/pubsubNoPageRef");

import upsertDataImport from "@salesforce/apex/GE_GiftEntryController.upsertDataImport";
import retrieveDefaultSGERenderWrapper from "@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper";

import { getInvalidFields } from "c/geFormSection";

jest.mock("c/geFormSection");
jest.mock(
    "@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper",
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    "@salesforce/apex/GE_GiftEntryController.upsertDataImport",
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock("c/geReviewDonations");

const mockWrapperWithNoNames = require("./data/renderWrapper.json");
const getRecordContact1Imported = require("./data/getRecordContact1Imported.json");
const dataImportBatchRecord = require("./data/dataImportBatchRecord.json");

describe("c-ge-form-renderer", () => {
    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    describe("render behavior", () => {
        it("when a form is saved with a possible validation rule error then processing of the donation should be halted", async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getInvalidFields.mockReturnValue([]); // form has no invalid fields, so save proceeds to apex

            const validationRuleErrorResponse = {
                status: 500,
                body: {
                    exceptionType: "System.DmlException",
                    isUserDefinedException: false,
                    message:
                        '{"exceptionType":"System.DmlException",' +
                        '"errorMessage":null,' +
                        '"DMLErrorMessageMapping":' +
                        '{"0":"Donation has to be more than $5"},' +
                        '"DMLErrorFieldNameMapping":{}}',
                    stackTrace: "",
                },
                headers: {},
            };
            upsertDataImport.mockRejectedValue(validationRuleErrorResponse);

            const element = createElement("c-ge-form-renderer", { is: GeFormRenderer });
            document.body.appendChild(element);

            await flushPromises();

            const DUMMY_CONTACT_ID = "003J000001zoYLGIA2";
            element.giftInView = {
                fields: {
                    Donation_Amount__c: "0.01",
                    Contact1Imported__c: DUMMY_CONTACT_ID,
                    Donation_Date__c: "2021-02-23",
                    Donation_Donor__c: "Contact",
                    Contact1_Lastname__c: "DummyLastName",
                },
                softCredits: { all: [] },
            };
            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            getRecord.emit(getRecordContact1Imported, (config) => {
                return config.recordId === DUMMY_CONTACT_ID;
            });
            await flushPromises();

            getObjectInfo.emit({ fields: {} }, (config) => config.objectApiName.objectApiName === "DataImport__c");
            await flushPromises();

            const saveButton = element.shadowRoot.querySelectorAll("lightning-button")[1];
            saveButton.click();
            await flushPromises();

            expect(upsertDataImport).toHaveBeenCalledTimes(1);

            const pageLevelMessage = element.shadowRoot.querySelector("c-util-page-level-message");
            const pElement = pageLevelMessage.querySelector("p");
            expect(pElement.innerHTML).toBe("Donation has to be more than $5");
            const spinner = element.shadowRoot.querySelector("lightning-spinner");
            expect(spinner).toBeFalsy();
        });
        it("make recurring button is disabled when imported gift is loaded into the form", async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
const element = createElement("c-ge-form-renderer", { is: GeFormRenderer });

            const DUMMY_BATCH_ID = "a0T11000007F8WQEA0";

            element.batchId = DUMMY_BATCH_ID;
            document.body.appendChild(element);
            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            getRecord.emit(dataImportBatchRecord, (config) => {
                return config.recordId === DUMMY_BATCH_ID;
            });

            await flushPromises();

            const button = element.shadowRoot.querySelectorAll('[data-id="recurringButton"]');
            expect(button).toHaveLength(1);

            element.isMakeRecurringButtonDisabled = true;
            await flushPromises();

            const disabledButton = element.shadowRoot.querySelectorAll('[data-id="recurringButton"]');
            expect(disabledButton[0].disabled).toBe(true);
        });

        it("save button is not disabled when schedule recurring type is Fixed for non-Elevate RD", async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);

            const element = createElement("c-ge-form-renderer", { is: GeFormRenderer });
            element.batchId = "DUMMY_BATCH_ID";

            document.body.appendChild(element);
            await flushPromises();

            element.giftInView = {
                fields: {
                    Recurring_Donation_Recurring_Type__c: "Fixed",
                    Payment_Method__c: "Credit Card",
                },
            };
            await flushPromises();

            const saveButton = element.shadowRoot.querySelector('[data-id="bgeSaveButton"]');
            expect(saveButton.disabled).toBeFalsy();
        });

        it("renders make recurring button, when in batch mode and feature is enabled", async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
const element = createElement("c-ge-form-renderer", { is: GeFormRenderer });

            const DUMMY_BATCH_ID = "a0T11000007F8WQEA0";

            document.body.appendChild(element);
            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            element.batchId = DUMMY_BATCH_ID;
            await flushPromises();

            getRecord.emit(dataImportBatchRecord, (config) => {
                return config.recordId === DUMMY_BATCH_ID;
            });
            await flushPromises();

            const button = element.shadowRoot.querySelectorAll('[data-id="recurringButton"]');
            expect(button).toHaveLength(1);
        });

        it("does not render make recurring button, when in batch mode and feature is disabled", async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
const element = createElement("c-ge-form-renderer", { is: GeFormRenderer });
            const DUMMY_BATCH_ID = "a0T11000007F8WQEA0";

            element.batchId = DUMMY_BATCH_ID;

            dataImportBatchRecord.fields.Allow_Recurring_Donations__c.value = "false";

            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            getRecord.emit(dataImportBatchRecord, (config) => {
                return config.recordId === DUMMY_BATCH_ID;
            });

            await flushPromises();

            const button = element.shadowRoot.querySelectorAll('[data-id="recurringButton"]');
            expect(button).toHaveLength(0);
        });

        it("does not render make recurring button, when in single mode", async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
const element = createElement("c-ge-form-renderer", { is: GeFormRenderer });

            document.body.appendChild(element);
            await flushPromises();

            const button = element.shadowRoot.querySelectorAll('[data-id="recurringButton"]');
            expect(button).toHaveLength(0);
        });
    });

    describe("events", () => {
        it("dispatches an event to display recurring donation schedule modal", async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
const element = createElement("c-ge-form-renderer", { is: GeFormRenderer });
            const DUMMY_BATCH_ID = "a0T11000007F8WQEA0";

            element.batchId = DUMMY_BATCH_ID;

            document.body.appendChild(element);

            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            getRecord.emit(dataImportBatchRecord, (config) => {
                return config.recordId === DUMMY_BATCH_ID;
            });

            await flushPromises();

            const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");
            const button = element.shadowRoot.querySelector('[data-id="recurringButton"]');
            button.click();

            await flushPromises();

            expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
            const componentName = dispatchEventSpy.mock.calls[0][0].detail.modalProperties.componentName;
            expect(componentName).toBe("geModalRecurringDonation");
        });

        it("dispatches an event to display a warning modal when adding schedule for gift with net new soft credits", async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
const element = createElement("c-ge-form-renderer", { is: GeFormRenderer });
            const DUMMY_BATCH_ID = "a0T11000007F8WQEA0";

            element.batchId = DUMMY_BATCH_ID;

            document.body.appendChild(element);

            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            getRecord.emit(dataImportBatchRecord, (config) => {
                return config.recordId === DUMMY_BATCH_ID;
            });
            element.giftInView = {
                fields: {
                    Payment_Method__c: "Credit Card",
                    Donation_Amount__c: "0.01",
                },
                softCredits: '[{"Role":"", "ContactId":"", "key":0}]',
            };

            await flushPromises();

            const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");
            const button = element.shadowRoot.querySelector('[data-id="recurringButton"]');
            button.click();

            await flushPromises();

            expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
            const componentName = dispatchEventSpy.mock.calls[0][0].detail.modalProperties.componentName;
            expect(componentName).toBe("geModalPrompt");
        });
    });

    it("loads sections from the render wrapper", async () => {
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        const element = createElement("c-ge-form-renderer", { is: GeFormRenderer });

        document.body.appendChild(element);
        await flushPromises();

        expect(retrieveDefaultSGERenderWrapper).toHaveBeenCalledTimes(1);
        const sections = element.shadowRoot.querySelectorAll("c-ge-form-section");
        expect(sections.length).toBeGreaterThan(0);
    });

    it("form when saving without filling anything in should result in a page level error for missing fields", async () => {
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        // geFormSection reports these three required fields as invalid (no values filled in)
        getInvalidFields.mockReturnValue(["Donor Type", "Donation Date", "Donation Amount"]);

        const element = createElement("c-ge-form-renderer", { is: GeFormRenderer });
        document.body.appendChild(element);

        await flushPromises();
        const saveButton = element.shadowRoot.querySelectorAll("lightning-button")[1];
        saveButton.click();

        await flushPromises();

        const pageLevelMessage = element.shadowRoot.querySelector("c-util-page-level-message");
        const pElement = pageLevelMessage.querySelector("p");

        expect(pElement.innerHTML).toBe(
            "The following fields are required: Donor Type, Donation Date, Donation Amount"
        );
    });

});
