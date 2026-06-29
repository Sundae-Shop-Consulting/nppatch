import { LightningElement, api } from "lwc";
import CUSTOM_LABELS from "./helpers/customLabels";

export default class GeBatchGiftEntryHeader extends LightningElement {
    LABELS = CUSTOM_LABELS;
    ACTIONS = Object.freeze({
        DRY_RUN_BATCH: "DRY_RUN_BATCH",
        PROCESS_BATCH: "PROCESS_BATCH",
        EDIT_BATCH: "EDIT_BATCH",
    });

    @api giftBatchState;
    _isGiftBatchProcessing;
    @api get isGiftBatchProcessing() {
        return this._isGiftBatchProcessing;
    }
    set isGiftBatchProcessing(value) {
        this._isGiftBatchProcessing = value;
    }

    get batchName() {
        return this.giftBatchState.name;
    }

    get shouldDisplayHeaderDetails() {
        return this.giftBatchState.hasValuesGreaterThanZero;
    }

    handleClick(event) {
        const action = event.target.getAttribute("data-action");
        switch (action) {
            case this.ACTIONS.DRY_RUN_BATCH:
                this.dispatchEvent(new CustomEvent("batchdryrun"));
                break;
            case this.ACTIONS.PROCESS_BATCH:
                this.dispatchEvent(new CustomEvent("processbatch"));
                this._isGiftBatchProcessing = true;
                break;
            case this.ACTIONS.EDIT_BATCH:
                this.editBatch();
                break;
            default:
                break;
        }
    }

    editBatch() {
        this.dispatchEvent(new CustomEvent("edit", { detail: this.giftBatchState.id }));
    }

    get qaLocatorBatchDryRun() {
        return `button ${this.LABELS.bgeBatchDryRun}`;
    }
    get qaLocatorProcessBatch() {
        return `button ${this.LABELS.bgeProcessBatch}`;
    }
    get qaLocatorEditBatchInfo() {
        return `button ${this.LABELS.geEditBatchInfo}`;
    }
}
