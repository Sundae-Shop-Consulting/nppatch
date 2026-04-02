import { LightningElement, api, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import getContactName from "@salesforce/apex/RelationshipsTreeGridController.getContactName";
import accessDeniedMessage from "@salesforce/label/c.addrCopyConAddBtnFls";
import insufficientPermissions from "@salesforce/label/c.commonInsufficientPermissions";
import graphicalView from "@salesforce/label/c.REL_ViewerGraphical";
import tabularView from "@salesforce/label/c.REL_ViewerTabular";

export default class RelationshipsNavigator extends LightningElement {
    contactId;

    @api
    get recordId() {
        return this.contactId;
    }
    set recordId(value) {
        this.contactId = value;
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(pageRef) {
        if (pageRef?.state?.c__recordId) {
            this.contactId = pageRef.state.c__recordId;
            this._tabularTabReady = false;
            this.error = undefined;
        }
    }

    labels = {
        accessDeniedMessage,
        insufficientPermissions,
        graphicalView,
        tabularView,
    };

    _contactName;

    @wire(getContactName, { contactId: "$contactId" })
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
