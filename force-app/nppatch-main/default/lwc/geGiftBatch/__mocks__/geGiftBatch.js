export const init = jest.fn();
export const addMember = jest.fn();
export const updateMember = jest.fn();
export const remove = jest.fn();
export const mostRecentGift = jest.fn();
export const getMoreGifts = jest.fn();
export const findGiftBy = jest.fn();
export const latestState = jest.fn();
export const giftsInViewSize = jest.fn();
export const refreshTotals = jest.fn();
export const dryRun = jest.fn();
export const updateWith = jest.fn();
export const matchesExpectedCountOfGifts = jest.fn();
export const matchesExpectedTotalBatchAmount = jest.fn();

export default class GiftBatch {
    init = init;
    addMember = addMember;
    updateMember = updateMember;
    remove = remove;
    mostRecentGift = mostRecentGift;
    getMoreGifts = getMoreGifts;
    findGiftBy = findGiftBy;
    latestState = latestState;
    giftsInViewSize = giftsInViewSize;
    refreshTotals = refreshTotals;
    dryRun = dryRun;
    updateWith = updateWith;
    matchesExpectedCountOfGifts = matchesExpectedCountOfGifts;
    matchesExpectedTotalBatchAmount = matchesExpectedTotalBatchAmount;
}
