export const isImported = jest.fn();
export const state = jest.fn();
export const updateFieldsWith = jest.fn();
export const asDataImport = jest.fn();
export const removeField = jest.fn();
export const addSchedule = jest.fn();
export const removeSchedule = jest.fn();
export const hasProcessedSoftCredits = jest.fn();
export const clearProcessedSoftCredits = jest.fn();
export const addProcessedSoftCredits = jest.fn();
export const addNewSoftCredit = jest.fn();
export const removeSoftCredit = jest.fn();
export const updateSoftCredit = jest.fn();
export const donationId = jest.fn();

export default class Gift {
    isImported = isImported;
    state = state;
    updateFieldsWith = updateFieldsWith;
    asDataImport = asDataImport;
    removeField = removeField;
    addSchedule = addSchedule;
    removeSchedule = removeSchedule;
    hasProcessedSoftCredits = hasProcessedSoftCredits;
    clearProcessedSoftCredits = clearProcessedSoftCredits;
    addProcessedSoftCredits = addProcessedSoftCredits;
    addNewSoftCredit = addNewSoftCredit;
    removeSoftCredit = removeSoftCredit;
    updateSoftCredit = updateSoftCredit;
    donationId = donationId;
}
