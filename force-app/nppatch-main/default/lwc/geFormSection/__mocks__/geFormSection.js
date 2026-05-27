import { LightningElement, api } from 'lwc';

export const getInvalidFields = jest.fn();
export const setCustomValidityOnFields = jest.fn();
export const getAllFieldsByAPIName = jest.fn(() => ({}));

export default class GeFormSection extends LightningElement {
    @api section;
    @api formState;
    @api giftInView;

    @api getInvalidFields() { return getInvalidFields(); }
    @api setCustomValidityOnFields(...args) { return setCustomValidityOnFields(...args); }
    @api getAllFieldsByAPIName() { return getAllFieldsByAPIName(); }
}
