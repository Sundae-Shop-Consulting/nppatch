import { LightningElement, api, wire } from "lwc";
import getContactName from "@salesforce/apex/RelationshipsTreeGridController.getContactName";
import accessDeniedMessage from "@salesforce/label/c.addrCopyConAddBtnFls";
import insufficientPermissions from "@salesforce/label/c.commonInsufficientPermissions";
import graphicalView from "@salesforce/label/c.REL_ViewerGraphical";
import tabularView from "@salesforce/label/c.REL_ViewerTabular";

export default class RelationshipsNavigator extends LightningElement {
    @api recordId;

    @api
    set isLightningOut(val) {
        this._isLightningOut = val;
    }

    get isLightningOut() {
        return this._isLightningOut;
    }
    _isLightningOut;

    labels = {
        accessDeniedMessage,
        insufficientPermissions,
        graphicalView,
        tabularView,
    };

    _contactName;

    @wire(getContactName, { contactId: "$recordId" })
    wiredContactName({ data }) {
        if (data) {
            this._contactName = data;
        }
    }

    error;
    _tabularTabReady = false;

    handleTabularTabActive() {
        this._tabularTabReady = true;
    }

    handleAccessError(event) {
        this.error = event.detail;
    }

    get contactName() {
        return this._contactName;
    }
}
