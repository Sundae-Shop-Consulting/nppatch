import { LightningElement, api } from "lwc";
import { isUndefined } from "c/utilCommon";

const COLLAPSED_DISPLAY_MODE = "collapsed";

export default class GeFormSection extends LightningElement {
    @api section;
    @api formState;
    @api giftInView;

    /**
     * Get the alternative text that represents the section expand/collapse button
     * @returns {string} containing the section expand alternative text
     */
    get altTextLabel() {
        return "Toggle " + this.section.label;
    }

    get isCollapsed() {
        return this.section.defaultDisplayMode === COLLAPSED_DISPLAY_MODE;
    }

    /**
     * Sets custom validity on fields inside fieldsArray
     * @param {*} fieldsArray
     * @param {*} errorMessage
     */
    @api
    setCustomValidityOnFields(fieldsArray, errorMessage) {
        const fields = this.template.querySelectorAll("c-ge-form-field");
        if (fields !== null && typeof fields !== "undefined") {
            fields.forEach((f) => {
                if (fieldsArray.indexOf(f.sourceFieldAPIName) !== -1) {
                    f.setCustomValidity(errorMessage);
                }
            });
        }
    }

    /**
     * Get a list of fields that are required, but are null/undefined or otherwise blank in the dynamic form
     * @returns {Array} of invalid fields. If all fields are ok, the array is empty.
     */
    @api
    getInvalidFields() {
        const fields = this.template.querySelectorAll("c-ge-form-field");
        const invalidFields = [];

        fields.forEach((f) => {
            if (!f.isValid()) {
                invalidFields.push(f.fieldLabel);
            }
        });

        return invalidFields;
    }

    @api
    getAllFieldsByAPIName() {
        const fields = this.template.querySelectorAll("c-ge-form-field");
        const fieldMappedByAPIName = {};

        fields.forEach((f) => {
            fieldMappedByAPIName[f.sourceFieldAPIName] = f;
        });

        return fieldMappedByAPIName;
    }

    get renderableElements() {
        if (isUndefined(this.section)) {
            return [];
        }
        return this.section.elements.filter((e) => e.isRenderable);
    }
}
