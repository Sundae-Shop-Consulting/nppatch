import { LightningElement, api } from 'lwc';

export default class GeReviewDonations extends LightningElement {
    @api donorId;
    @api giftInView;
    @api selectedDonation;
}
