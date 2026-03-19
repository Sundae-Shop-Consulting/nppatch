import { api, LightningElement } from "lwc";
import getContactIdByUserId from "@salesforce/apex/DonationHistoryController.getContactIdByUserId";

export default class GivingSummaryForDetailPage extends LightningElement {
    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
    }

    connectedCallback() {
        if (!this._recordId) {
            getContactIdByUserId().then((recordId) => {
                this._recordId = recordId;
            });
        }
    }
}
