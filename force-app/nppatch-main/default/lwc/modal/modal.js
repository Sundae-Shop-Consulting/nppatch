import { LightningElement, api, track } from "lwc";
import closeLabel from "@salesforce/label/c.commonClose";

const MODAL_HIDDEN = "modal-hidden";
const ESCAPE = "Escape";

export default class Modal extends LightningElement {
    close = closeLabel;

    @api size = "fixed";
    @api isNested = false;
    @api hideBodyPadding = false;
    @api scrollModifier;
    @api doInsteadOfHide;

    visibilityClass = MODAL_HIDDEN;

    @api
    set defaultVisible(value) {
        if (value) {
            this.visibilityClass = "";
        } else {
            this.visibilityClass = MODAL_HIDDEN;
        }
    }
    get defaultVisible() {
        return this.visibilityClass === "";
    }

    @api
    set header(value) {
        this.hasHeaderString = value !== "";
        this._headerPrivate = value;
    }
    get header() {
        return this._headerPrivate;
    }

    renderedCallback() {
        if (!this._rendered && this.defaultVisible) {
            this._rendered = true;
            this.focus();
            return;
        }
        this._rendered = true;
    }

    get modalCss() {
        return (
            "slds-modal slds-fade-in-open slds-align_absolute-center" +
            (this.size === "fixed" ? "" : ` slds-modal_${this.size}`) +
            (this.isNested ? " nested-modal" : "")
        );
    }

    get modalContainerCss() {
        return "slds-modal__container" + (this.size === "fixed" ? " fixed-width" : "");
    }

    get bodyCss() {
        return (
            "slds-modal__content" +
            (this.scrollModifier
                ? " slds-scrollable_" + this.scrollModifier
                : " slds-scrollable") +
            (this.hideBodyPadding ? "" : " slds-p-around_medium")
        );
    }

    @track hasHeaderString = false;
    _headerPrivate;

    @api show() {
        const outerDivEl = this.template.querySelector("div");
        outerDivEl.classList.remove(MODAL_HIDDEN);
        this.focus();
    }

    @api hide() {
        const outerDivEl = this.template.querySelector("div");
        outerDivEl.classList.add(MODAL_HIDDEN);
    }

    handleDialogClose() {
        if (this.doInsteadOfHide) {
            this.doInsteadOfHide();
            return;
        }
        this.hide();
        this.dispatchEvent(new CustomEvent("dialogclose"));
    }

    handleEscapeKey(event) {
        if (event.key === ESCAPE) {
            this.handleDialogClose();
        }
    }

    handleSlotTaglineChange() {
        const taglineEl = this.template.querySelector("p");
        taglineEl.classList.remove(MODAL_HIDDEN);
    }

    handleSlotFooterChange() {
        const footerEl = this.template.querySelector("footer");
        footerEl.classList.remove(MODAL_HIDDEN);
    }

    focus() {
        const header = this.template.querySelector("h2");
        if (!header) {
            return;
        }
        header.focus();
    }
}
