import GiftBatch from "c/geGiftBatch";
import getGiftBatchViewWithLimitsAndOffsets from "@salesforce/apex/GE_GiftEntryController.getGiftBatchViewWithLimitsAndOffsets";
import hasActiveRunningJob from "@salesforce/apex/GE_GiftEntryController.hasActiveRunningJob";
import isGiftBatchAccessible from "@salesforce/apex/GE_GiftEntryController.isGiftBatchAccessible";

jest.mock("c/geGift");

jest.mock(
    "@salesforce/apex/GE_GiftEntryController.getGiftBatchViewWithLimitsAndOffsets",
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    "@salesforce/apex/GE_GiftEntryController.hasActiveRunningJob",
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    "@salesforce/apex/GE_GiftEntryController.isGiftBatchAccessible",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const BATCH_VIEW = {
    giftBatchId: "DUMMY_GIFT_BATCH_ID",
    name: "DUMMY GIFT BATCH NAME",
    totalDonationsAmount: 246.76,
    requireTotalMatch: false,
    expectedCountOfGifts: 0,
    expectedTotalBatchAmount: 0,
    batchTableColumns: "",
    currencyIsoCode: "USD",
    lastModifiedDate: "2024-01-01T00:00:00.000Z",
    totals: { TOTAL: 3, PROCESSED: 0, FAILED: 0, PROCESSING: 0 },
    gifts: [{}, {}, {}],
};

describe("ge-gift-batch", () => {
    afterEach(() => {
        jest.clearAllMocks();
    });

    async function flushPromises() {
        return new Promise((resolve) => setTimeout(resolve, 0));
    }

    it("should initialize with expected properties", async () => {
        getGiftBatchViewWithLimitsAndOffsets.mockResolvedValue(BATCH_VIEW);
        hasActiveRunningJob.mockResolvedValue(false);
        isGiftBatchAccessible.mockResolvedValue(true);

        const giftBatch = new GiftBatch();
        await giftBatch.init(BATCH_VIEW.giftBatchId);
        await flushPromises();

        expect(giftBatch.state().id).toBe("DUMMY_GIFT_BATCH_ID");
        expect(giftBatch.state().name).toBe("DUMMY GIFT BATCH NAME");
        expect(giftBatch.state().totalDonationsAmount).toEqual(246.76);
        expect(giftBatch.state().gifts.length).toEqual(3);
        expect(giftBatch.state().processedGiftsCount).toEqual(0);
        expect(giftBatch.state().failedGiftsCount).toEqual(0);
        expect(giftBatch.state().totalGiftsCount).toEqual(3);
        expect(giftBatch.state().hasValuesGreaterThanZero).toEqual(false);
        expect(giftBatch.state().isProcessingGifts).toBeFalsy();
    });

    it("should be in processing state", async () => {
        getGiftBatchViewWithLimitsAndOffsets.mockResolvedValue(BATCH_VIEW);
        hasActiveRunningJob.mockResolvedValue(true);
        isGiftBatchAccessible.mockResolvedValue(true);

        const giftBatch = new GiftBatch();
        await giftBatch.init(BATCH_VIEW.giftBatchId);
        await flushPromises();

        expect(giftBatch.state().isProcessingGifts).toBeTruthy();
    });

    it("should not be in processing state", async () => {
        getGiftBatchViewWithLimitsAndOffsets.mockResolvedValue(BATCH_VIEW);
        hasActiveRunningJob.mockResolvedValue(false);
        isGiftBatchAccessible.mockResolvedValue(true);

        const giftBatch = new GiftBatch();
        await giftBatch.init(BATCH_VIEW.giftBatchId);
        await flushPromises();

        expect(giftBatch.state().isProcessingGifts).toBeFalsy();
    });
});
