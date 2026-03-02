import { api, LightningElement } from "lwc";

export default class UtilScreenReaderAnnouncer extends LightningElement {
    @api priority = "polite";

    @api
    announce(message) {
        // eslint-disable-next-line @lwc/lwc/no-inner-html
        this.template.querySelector('div[data-id="liveregion"]').innerHTML = message;
    }
}
