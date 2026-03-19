import { LightningElement, api } from "lwc";
import { getChildObjectByName } from "c/util";

import ChangeAddress from "@salesforce/label/c.ChangeAddress";
import SelectExistingAddress from "@salesforce/label/c.SelectExistingAddress";
import EnterNewAddress from "@salesforce/label/c.EnterNewAddress";
import SetAddress from "@salesforce/label/c.SetAddress";
import stgBtnCancel from "@salesforce/label/c.stgBtnCancel";
import lblStreet from "@salesforce/label/c.lblStreet";
import lblCity from "@salesforce/label/c.lblCity";
import lblState from "@salesforce/label/c.lblState";
import lblPostalCode from "@salesforce/label/c.lblPostalCode";
import lblCountry from "@salesforce/label/c.lblCountry";

export default class ManageHhAddressManager extends LightningElement {
    @api addressUndeliverableLabel = "";

    _listAddr = [];
    _defaultAddress = null;
    showChangeAddressPopup = false;
    selectedAddressIndex = 0;
    newAddress = {};

    @api
    get listAddr() {
        return this._listAddr;
    }
    set listAddr(value) {
        this._listAddr = value || [];
        this._updateDefaultAddress();
    }

    @api
    get addrDefault() {
        return this._defaultAddress;
    }

    get changeAddressLabel() {
        return ChangeAddress;
    }
    get selectExistingLabel() {
        return SelectExistingAddress;
    }
    get enterNewLabel() {
        return EnterNewAddress;
    }
    get setAddressLabel() {
        return SetAddress;
    }
    get cancelLabel() {
        return stgBtnCancel;
    }
    get streetLabel() {
        return lblStreet;
    }
    get cityLabel() {
        return lblCity;
    }
    get stateLabel() {
        return lblState;
    }
    get postalCodeLabel() {
        return lblPostalCode;
    }
    get countryLabel() {
        return lblCountry;
    }

    get hasDefaultAddress() {
        return this._defaultAddress !== null;
    }

    get formattedDefaultAddress() {
        return this._formatAddress(this._defaultAddress);
    }

    get defaultAddressIsUndeliverable() {
        if (!this._defaultAddress) {
            return false;
        }
        return getChildObjectByName(this._defaultAddress, "Undeliverable__c");
    }

    get addresses() {
        return this._listAddr.map((addr, idx) => {
            const isUndeliverable = getChildObjectByName(addr, "Undeliverable__c");
            return {
                ...addr,
                _key: `addr-${idx}`,
                formattedAddress: this._formatAddress(addr),
                isUndeliverable: isUndeliverable,
                isSelected: idx === this.selectedAddressIndex ? "true" : "false",
                selectedClass: idx === this.selectedAddressIndex ? "slds-item selected" : "slds-item",
            };
        });
    }

    _updateDefaultAddress() {
        const defaultAddr = this._listAddr.find((addr) => getChildObjectByName(addr, "Default_Address__c"));
        this._defaultAddress = defaultAddr || this._listAddr[0] || null;
        // Update selected index to match default
        this.selectedAddressIndex = this._listAddr.indexOf(this._defaultAddress);
        if (this.selectedAddressIndex < 0) {
            this.selectedAddressIndex = 0;
        }
    }

    _formatAddress(addr) {
        if (!addr) {
            return "";
        }
        const street = getChildObjectByName(addr, "MailingStreet__c") || "";
        const street2 = getChildObjectByName(addr, "MailingStreet2__c");
        const city = getChildObjectByName(addr, "MailingCity__c") || "";
        const state = getChildObjectByName(addr, "MailingState__c") || "";
        const postal = getChildObjectByName(addr, "MailingPostalCode__c") || "";
        const country = getChildObjectByName(addr, "MailingCountry__c") || "";

        const parts = [];
        let streetLine = street;
        if (street2) {
            streetLine += "\n" + street2;
        }
        if (streetLine) {
            parts.push(streetLine);
        }

        const cityLine = [city, state].filter(Boolean).join(", ");
        const cityPostal = [cityLine, postal].filter(Boolean).join(" ");
        if (cityPostal) {
            parts.push(cityPostal);
        }
        if (country) {
            parts.push(country);
        }

        return parts.join("\n");
    }

    openChangeAddress() {
        this.newAddress = {
            MailingStreet__c: "",
            MailingCity__c: "",
            MailingState__c: "",
            MailingPostalCode__c: "",
            MailingCountry__c: "",
        };
        this.showChangeAddressPopup = true;
    }

    cancelChangeAddress() {
        this.showChangeAddressPopup = false;
    }

    handleSelectAddress(event) {
        this.selectedAddressIndex = parseInt(event.currentTarget.dataset.index, 10);
    }

    handleNewAddressChange(event) {
        const field = event.target.dataset.field;
        this.newAddress = { ...this.newAddress, [field]: event.target.value };
    }

    saveChangeAddress() {
        // Determine which section is active
        const accordion = this.template.querySelector("lightning-accordion");
        const activeSection = accordion ? accordion.activeSectionName : "existing-address-section";

        let selectedAddr;
        let updatedList = [...this._listAddr];

        if (activeSection === "new-address-section") {
            // Add new address to list
            selectedAddr = { ...this.newAddress, sobjectType: "Address__c" };
            updatedList.push(selectedAddr);
        } else {
            selectedAddr = updatedList[this.selectedAddressIndex];
        }

        // Clear all default flags, set selected as default
        updatedList = updatedList.map((addr) => {
            const copy = { ...addr };
            if (copy.Default_Address__c !== undefined) {
                copy.Default_Address__c = false;
            }
            if (copy.nppatch__Default_Address__c !== undefined) {
                copy.nppatch__Default_Address__c = false;
            }
            return copy;
        });

        const selectedIndex = updatedList.indexOf(selectedAddr);
        if (selectedIndex >= 0) {
            updatedList[selectedIndex] = { ...updatedList[selectedIndex] };
            updatedList[selectedIndex].Default_Address__c = true;
        }

        this.showChangeAddressPopup = false;

        this.dispatchEvent(
            new CustomEvent("addresschanged", {
                detail: {
                    address: selectedAddr,
                    addresses: updatedList,
                },
            })
        );
    }
}
