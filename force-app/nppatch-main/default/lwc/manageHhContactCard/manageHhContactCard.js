import { LightningElement, api } from "lwc";
import { getChildObjectByName } from "c/util";

import lblAddressOverride from "@salesforce/label/c.lblAddressOverride";
import lblCCardExcludeFrom from "@salesforce/label/c.lblCCardExcludeFrom";
import lblHouseholdName from "@salesforce/label/c.lblHouseholdName";
import lblFormalGreeting from "@salesforce/label/c.lblFormalGreeting";
import lblInformalGreeting from "@salesforce/label/c.lblInformalGreeting";

export default class ManageHhContactCard extends LightningElement {
    @api contact;
    @api index;
    @api totalContacts;
    @api contactUndeliverableLabel;

    labels = {
        addressOverride: lblAddressOverride,
        excludeFrom: lblCCardExcludeFrom,
        householdName: lblHouseholdName,
        formalGreeting: lblFormalGreeting,
        informalGreeting: lblInformalGreeting
    };

    get contactName() {
        if (!this.contact) return "";
        const first = this.contact.FirstName || "";
        const last = this.contact.LastName || "";
        return `${first} ${last}`.trim();
    }

    get isSavedContact() {
        return this.contact && this.contact.Id;
    }

    get contactUrl() {
        return this.contact ? `/${this.contact.Id}` : "";
    }

    get isFirst() {
        return this.index === 0;
    }

    get isLast() {
        return this.index === this.totalContacts - 1;
    }

    get hasAddress() {
        if (!this.contact) return false;
        return (
            this.contact.MailingStreet ||
            this.contact.MailingCity ||
            this.contact.MailingState ||
            this.contact.MailingPostalCode ||
            this.contact.MailingCountry
        );
    }

    get formattedAddress() {
        if (!this.contact) return "";
        const parts = [];
        if (this.contact.MailingStreet) parts.push(this.contact.MailingStreet);
        const cityLine = [
            this.contact.MailingCity,
            this.contact.MailingState
        ]
            .filter(Boolean)
            .join(", ");
        const cityPostal = [cityLine, this.contact.MailingPostalCode]
            .filter(Boolean)
            .join(" ");
        if (cityPostal) parts.push(cityPostal);
        if (this.contact.MailingCountry) parts.push(this.contact.MailingCountry);
        return parts.join("\n");
    }

    get isAddressOverride() {
        return getChildObjectByName(this.contact, "is_Address_Override__c");
    }

    get isUndeliverable() {
        return getChildObjectByName(
            this.contact,
            "Undeliverable_Address__c"
        );
    }

    get excludeFromName() {
        return getChildObjectByName(
            this.contact,
            "Exclude_from_Household_Name__c"
        );
    }

    get excludeFromFormalGreeting() {
        return getChildObjectByName(
            this.contact,
            "Exclude_from_Household_Formal_Greeting__c"
        );
    }

    get excludeFromInformalGreeting() {
        return getChildObjectByName(
            this.contact,
            "Exclude_from_Household_Informal_Greeting__c"
        );
    }

    get addressOverrideLabel() {
        return this.labels.addressOverride;
    }

    get excludeFromLabel() {
        return this.labels.excludeFrom;
    }

    get householdNameLabel() {
        return this.labels.householdName;
    }

    get formalGreetingLabel() {
        return this.labels.formalGreeting;
    }

    get informalGreetingLabel() {
        return this.labels.informalGreeting;
    }

    handleExclusionChange(event) {
        const field = event.target.dataset.field;
        const checked = event.target.checked;
        this.dispatchEvent(
            new CustomEvent("contactchanged", {
                detail: {
                    index: this.index,
                    field: field,
                    value: checked
                }
            })
        );
    }

    handleRemove() {
        this.dispatchEvent(
            new CustomEvent("contactremove", {
                detail: { index: this.index }
            })
        );
    }

    handleMoveUp() {
        this.dispatchEvent(
            new CustomEvent("contactreorder", {
                detail: { index: this.index, direction: "up" }
            })
        );
    }

    handleMoveDown() {
        this.dispatchEvent(
            new CustomEvent("contactreorder", {
                detail: { index: this.index, direction: "down" }
            })
        );
    }
}
