import { LightningElement, api, track } from "lwc";
import { isNull, isEmpty } from "c/util";

export default class customPicklistType extends LightningElement {
    @api label;
    @track _value;
    @api options;
    @api placeholder;
    @api keyField;
    @api disabled;

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val;
    }

    /**
     * @description Determines the label when value is read-only
     */
    get optionLabel() {
        let optionLabel = this.value;

        if (isNull(this.options) || isEmpty(this.options)) {
            return optionLabel;
        }

        for (let i = 0; i < this.options.length; i++) {
            if (this.options[i].value === this.value) {
                optionLabel = this.options[i].label;
                break;
            }
        }

        return optionLabel;
    }

    /***
     * @description Sets focus on the datatable cell containing the picklist field
     */
    handleFocus() {
        try {
            const field = this.template.querySelector('[data-id="picklist"]');
            field.parentElement.click();
        } catch (error) {
            /* no-op */
        }
    }

    /***
     * @description Propagates the picklist value change to the custom datatable event handler
     */
    handleChange(event) {
        this._value = event.detail.value;

        this.dispatchEvent(
            new CustomEvent("picklistchange", {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    data: { value: this.value, keyField: this.keyField },
                },
            })
        );
    }
}
