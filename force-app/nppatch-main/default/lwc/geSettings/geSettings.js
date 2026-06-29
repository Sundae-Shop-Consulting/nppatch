import isRecurringGiftsEnabled from "@salesforce/apex/GE_GiftEntryController.isRecurringGiftsEnabled";
import canMakeGiftsRecurring from "@salesforce/apex/GE_GiftEntryController.canMakeGiftsRecurring";

class GeSettings {
    _isRecurringGiftsEnabled = false;
    _canMakeGiftsRecurring = false;

    async init() {
        this._isRecurringGiftsEnabled = await isRecurringGiftsEnabled();
        this._canMakeGiftsRecurring = await canMakeGiftsRecurring();
    }

    canMakeGiftsRecurring() {
        return this._isRecurringGiftsEnabled && this._canMakeGiftsRecurring;
    }
}

const geSettings = new GeSettings();

export default geSettings;
