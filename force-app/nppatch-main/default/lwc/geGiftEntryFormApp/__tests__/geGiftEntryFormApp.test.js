import { createElement } from "lwc";
import { getNavigateCalledWith } from "lightning/navigation";
import DATA_IMPORT_BATCH_OBJECT from "@salesforce/schema/DataImportBatch__c";
import GeGiftEntryFormApp from "c/geGiftEntryFormApp";
import * as UtilTemplateBuilder from "c/utilTemplateBuilder";
import * as GiftBatch from "c/geGiftBatch";
import * as Gift from "c/geGift";

jest.mock("c/geGiftBatch");
jest.mock("c/geGift");
jest.mock('c/geFormRenderer');
jest.mock("lightning/navigation", () => require('mock-lightning/navigation'));

jest.mock("c/utilTemplateBuilder", () => ({
    handleError: jest.fn(),
}));

describe("c-ge-gift-entry-form-app", () => {
    beforeEach(() => {
        GiftBatch.init.mockReturnValue({isAccessible: true});
        Gift.asDataImport.mockReturnValue({});
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    async function flushPromises() {
        return new Promise((resolve) => setTimeout(resolve, 0));
    }

    describe("rendering behavior", () => {
        it("should render page blocker if the gift batch is inaccessible to the current user", async () => {
            GiftBatch.init.mockResolvedValue({isAccessible: false});

            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            expect(element.shadowRoot.querySelector("c-util-illustration")).not.toBeNull();
        });

        it("should not render page blocker if the gift batch is accessible to the current user", async () => {
            GiftBatch.init.mockResolvedValue({isAccessible: true});

            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            expect(element.shadowRoot.querySelector("c-util-illustration")).toBeNull();
            expect(element.shadowRoot.querySelector("c-ge-batch-gift-entry-header")).not.toBeNull();
            expect(element.shadowRoot.querySelector("c-ge-form-renderer")).not.toBeNull();
            expect(element.shadowRoot.querySelector("c-ge-batch-gift-entry-table")).not.toBeNull();
        });

        it("should render processing batch spinner if batch is still processing", async () => {
            GiftBatch.init.mockResolvedValue({isProcessingGifts: false});

            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            expect(element.shadowRoot.querySelector("lightning-spinner")).not.toBeNull();

            await flushPromises();

            expect(element.shadowRoot.querySelector("lightning-spinner")).toBeNull();
        });

        it("should render batch table in Batch mode", async () => {
            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            expect(element.shadowRoot.querySelector("c-ge-batch-gift-entry-table")).not.toBeNull();
            expect(element.shadowRoot.querySelector("c-ge-form-renderer")).not.toBeNull();
        });

        it("should not render batch table in Single mode", async () => {
            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            document.body.appendChild(element);

            await flushPromises();

            expect(element.shadowRoot.querySelector("c-ge-batch-gift-entry-table")).toBeNull();
        });
    });

    describe("event dispatch and handling behavior", () => {
        it("should dispatch edit batch event", async () => {
            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            const handler = jest.fn();
            element.addEventListener("editbatch", handler);

            document.body.appendChild(element);

            await flushPromises();

            const batchHeader = element.shadowRoot.querySelector("c-ge-batch-gift-entry-header");
            expect(batchHeader).not.toBeNull();

            batchHeader.dispatchEvent(new CustomEvent("edit"));
            expect(handler).toHaveBeenCalled();
        });

        it("should dispatch toggle modal event", async () => {
            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            const handler = jest.fn();
            element.addEventListener("togglemodal", handler);

            document.body.appendChild(element);
            await flushPromises();

            const formRenderer = element.shadowRoot.querySelector("c-ge-form-renderer");
            expect(formRenderer).not.toBeNull();

            formRenderer.dispatchEvent(new CustomEvent("togglemodal"));
            expect(handler).toHaveBeenCalled();
        });
    });

    describe("navigation behavior", () => {
        it("should navigate to record detail page", async () => {
            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            const formRenderer = element.shadowRoot.querySelector("c-ge-form-renderer");
            expect(formRenderer).not.toBeNull();

            formRenderer.dispatchEvent(new CustomEvent("navigate", {
                detail: { to: "recordPage", recordId: "FAKE_RECORD_ID" },
            }));

            const { pageReference } = getNavigateCalledWith();
            expect(pageReference.type).toBe("standard__recordPage");
            expect(pageReference.attributes.recordId).toBe("FAKE_RECORD_ID");
        });

        it("should navigate to Gift Entry landing page", async () => {
            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            const formRenderer = element.shadowRoot.querySelector("c-ge-form-renderer");
            expect(formRenderer).not.toBeNull();

            formRenderer.dispatchEvent(new CustomEvent("navigate", {
                detail: { to: "landingPage" },
            }));

            const { pageReference } = getNavigateCalledWith();
            expect(pageReference.type).toBe("standard__webPage");
            expect(pageReference.attributes.url).toContain("GE_Gift_Entry");
        });
    });

    describe("save, update, and delete behavior", () => {
        it("should call addGiftTo with expected arguments when a gift is saved in batch mode", async () => {
            GiftBatch.addMember.mockResolvedValue({isAccessible: true});
            GiftBatch.mostRecentGift.mockReturnValue({failureInformation: () => null});

            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            const formRenderer = element.shadowRoot.querySelector("c-ge-form-renderer");
            expect(formRenderer).not.toBeNull();

            const successCallback = jest.fn();
            const errorCallback = jest.fn();

            formRenderer.dispatchEvent(new CustomEvent("submit", {
                detail: { success: successCallback, error: errorCallback },
            }));

            await flushPromises();

            expect(GiftBatch.addMember).toHaveBeenCalled();
            expect(successCallback).toHaveBeenCalled();
            expect(errorCallback).not.toHaveBeenCalled();
        });

        it("should call expected methods when a gift save fails in batch mode", async () => {
            GiftBatch.addMember.mockResolvedValue({isAccessible: true});
            GiftBatch.mostRecentGift.mockReturnValue({failureInformation: () => "fail reason"});

            const element = createElement("c-ge-gift-entry-form-app", {is: GeGiftEntryFormApp});

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            const formRenderer = element.shadowRoot.querySelector("c-ge-form-renderer");
            expect(formRenderer).not.toBeNull();

            const successCallback = jest.fn();
            const errorCallback = jest.fn();

            formRenderer.dispatchEvent(new CustomEvent("submit", {
                detail: { success: successCallback, error: errorCallback },
            }));
            await flushPromises();

            expect(GiftBatch.addMember).toHaveBeenCalled();
            expect(errorCallback).toHaveBeenCalledWith("fail reason");
            expect(successCallback).not.toHaveBeenCalled();
        });
    });

    describe("field change behavior", () => {
        it("populates related fields for a contact when contact lookup changes", async () => {
            Gift.state.mockReturnValue({fields: {Amount__c: 100}});

            const element = createElement("c-ge-gift-entry-form-app", { is: GeGiftEntryFormApp });

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            const formRenderer = element.shadowRoot.querySelector("c-ge-form-renderer");
            expect(formRenderer).not.toBeNull();

            const fieldChanges = {Amount__c: 100};

            formRenderer.dispatchEvent(new CustomEvent("formstatechange", {
                detail: fieldChanges,
            }));
            await flushPromises();

            expect(Gift.updateFieldsWith).toHaveBeenCalledWith(fieldChanges);
            expect(formRenderer.giftInView).toEqual({fields: {Amount__c: 100}});
        });
    });

    describe("batch processing", () => {
        it("should not allow batch processing if total count of gifts is required and totals do not match", async () => {
            GiftBatch.init.mockReturnValue({
                isAccessible: true,
                expectedCountOfGifts: 5,
                requireTotalMatch: true,
            });

            GiftBatch.matchesExpectedCountOfGifts.mockReturnValue(false);

            const element = createElement("c-ge-gift-entry-form-app", { is: GeGiftEntryFormApp });

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            element.shadowRoot.querySelector("c-ge-batch-gift-entry-header").dispatchEvent(
                new CustomEvent("processbatch")
            );

            await flushPromises();

            expect(element.shadowRoot.querySelector("lightning-spinner")).toBeNull();
            expect(UtilTemplateBuilder.handleError).toHaveBeenCalledWith("c.geBatchGiftsExpectedCountOrTotalMessage");
        });

        it("should not allow batch processing if both types of totals are required and totals do not match", async () => {
            GiftBatch.init.mockReturnValue({
                isAccessible: true,
                expectedCountOfGifts: 5,
                expectedTotalBatchAmount: 100,
                requireTotalMatch: true,
            });

            GiftBatch.matchesExpectedCountOfGifts.mockReturnValue(false);
            GiftBatch.matchesExpectedTotalBatchAmount.mockReturnValue(false);

            const element = createElement("c-ge-gift-entry-form-app", { is: GeGiftEntryFormApp });

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            element.shadowRoot.querySelector("c-ge-batch-gift-entry-header").dispatchEvent(
                new CustomEvent("processbatch")
            );

            await flushPromises();

            expect(element.shadowRoot.querySelector("lightning-spinner")).toBeNull();
            expect(UtilTemplateBuilder.handleError).toHaveBeenCalledWith("c.geBatchGiftsExpectedTotalsMessage");
        });

        it("should allow batch processing if both types of totals are required and totals match", async () => {
            const giftBatchState = {
                isAccessible: true,
                expectedCountOfGifts: 5,
                expectedTotalBatchAmount: 100,
                requireTotalMatch: true,
            };
            GiftBatch.init.mockReturnValue(giftBatchState);
            GiftBatch.refreshTotals.mockReturnValue(giftBatchState);

            GiftBatch.matchesExpectedCountOfGifts.mockReturnValue(true);
            GiftBatch.matchesExpectedTotalBatchAmount.mockReturnValue(true);

            const element = createElement("c-ge-gift-entry-form-app", { is: GeGiftEntryFormApp });

            element.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            element.recordId = "FAKE_RECORD_ID";

            document.body.appendChild(element);

            await flushPromises();

            element.shadowRoot.querySelector("c-ge-batch-gift-entry-header").dispatchEvent(
                new CustomEvent("processbatch")
            );

            await flushPromises();

            expect(element.shadowRoot.querySelector("lightning-spinner")).not.toBeNull();
            expect(element.shadowRoot.querySelector(".loading-text").textContent).toBe("c.geProcessingBatch");
        });
    });
});
