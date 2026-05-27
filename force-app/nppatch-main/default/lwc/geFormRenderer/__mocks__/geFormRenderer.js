import { LightningElement, api } from 'lwc';

export default class GeFormRenderer extends LightningElement {
    @api batchId;
    @api loadingText;
    @api batchCurrencyIsoCode;
    @api giftInView;
    @api isFormCollapsed;
    @api saveDisabled;
    @api isMakeRecurringButtonDisabled;
}
