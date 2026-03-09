import { api } from "lwc";
import LightningModal from "lightning/modal";

const DONATION_MATCHING_OPTIONS = [
    { label: "Do Not Match", value: "Do Not Match" },
    { label: "No Match", value: "No Match" },
    { label: "Single Match", value: "Single Match" },
    { label: "Single Match or Create", value: "Single Match or Create" },
    { label: "Best Match", value: "Best Match" },
    { label: "Best Match or Create", value: "Best Match or Create" },
];

export default class BdiBatchConfigModal extends LightningModal {
    @api config = {};

    donationMatchingOptions = DONATION_MATCHING_OPTIONS;

    _localConfig = {};

    connectedCallback() {
        this._localConfig = { ...this.config };
    }

    get contactMatchingRule() {
        return this._localConfig.contactMatchingRule || "";
    }
    get donationMatchingRule() {
        return this._localConfig.donationMatchingRule || "";
    }
    get donationMatchingBehavior() {
        return this._localConfig.donationMatchingBehavior || "";
    }
    get donationDateRange() {
        return this._localConfig.donationDateRange;
    }
    get batchProcessSize() {
        return this._localConfig.batchProcessSize;
    }
    get contactCustomUniqueId() {
        return this._localConfig.contactCustomUniqueId || "";
    }
    get accountCustomUniqueId() {
        return this._localConfig.accountCustomUniqueId || "";
    }
    get donationMatchingClass() {
        return this._localConfig.donationMatchingClass || "";
    }
    get postProcessClass() {
        return this._localConfig.postProcessClass || "";
    }
    get runRollups() {
        return this._localConfig.runRollups || false;
    }
    get processUsingScheduledJob() {
        return this._localConfig.processUsingScheduledJob || false;
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        const value =
            event.target.type === "checkbox"
                ? event.target.checked
                : event.detail.value;
        this._localConfig = { ...this._localConfig, [field]: value };
    }

    handleSave() {
        this.close(this._localConfig);
    }

    handleCancel() {
        this.close(null);
    }
}
