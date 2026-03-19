import { LightningElement, api } from "lwc";
import { getChildObjectByName, debouncify } from "c/util";
import queryObjects from "@salesforce/apex/HH_AutoCompleteDataProvider_LCTRL.queryObjects";

import lblFindOrAddContact from "@salesforce/label/c.lblFindOrAddContact";
import lblFindInContacts from "@salesforce/label/c.lblFindInContacts";
import NewContact from "@salesforce/label/c.NewContact";

export default class ManageHhContactSearch extends LightningElement {
    @api contacts = [];

    searchTerm = "";
    searchResults = [];
    isSearching = false;
    isDropdownOpen = false;

    _debouncedSearch;

    get findOrAddLabel() {
        return lblFindOrAddContact;
    }

    get findInContactsLabel() {
        return lblFindInContacts;
    }

    get newContactLabel() {
        return NewContact;
    }

    get comboboxContainerClass() {
        let cls = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
        if (this.isDropdownOpen) {
            cls += " slds-is-open";
        }
        return cls;
    }

    connectedCallback() {
        this._debouncedSearch = debouncify(this._doSearch.bind(this), 300);
    }

    handleSearchInput(event) {
        this.searchTerm = event.target.value;
        if (this.searchTerm && this.searchTerm.length >= 2) {
            this.isSearching = true;
            this._debouncedSearch();
        } else {
            this.searchResults = [];
            this.isDropdownOpen = false;
            this.isSearching = false;
        }
    }

    async _doSearch() {
        try {
            // Add namespace prefix to contact fields for the Apex call
            const contactsForQuery = this.contacts.map((con) => {
                const c = { ...con, sobjectType: "Contact" };
                return c;
            });

            const results = await queryObjects({
                queryValue: this.searchTerm,
                listCon: contactsForQuery,
            });

            this.searchResults = results.map((r) => {
                const contact = r.value;
                const accountName = getChildObjectByName(contact, "Account")
                    ? getChildObjectByName(contact, "Account").Name
                    : "";
                return {
                    Id: contact.Id,
                    Name: r.displayValue,
                    AccountName: accountName,
                    record: contact,
                };
            });
            this.isDropdownOpen = true;
        } catch (error) {
            console.error("Search error:", error);
            this.searchResults = [];
        } finally {
            this.isSearching = false;
        }
    }

    handleSelectContact(event) {
        const contactId = event.currentTarget.dataset.id;
        const selected = this.searchResults.find((r) => r.Id === contactId);
        if (selected) {
            this.dispatchEvent(
                new CustomEvent("contactselected", {
                    detail: { contact: selected.record },
                })
            );
        }
        this._clearSearch();
    }

    handleNewContact() {
        const nameParts = (this.searchTerm || "").trim().split(/\s+/);
        const firstName = nameParts.length > 1 ? nameParts.slice(0, -1).join(" ") : "";
        const lastName = nameParts.length > 0 ? nameParts[nameParts.length - 1] : "";
        this.dispatchEvent(
            new CustomEvent("newcontact", {
                detail: { firstName, lastName },
            })
        );
        this._clearSearch();
    }

    _clearSearch() {
        this.searchTerm = "";
        this.searchResults = [];
        this.isDropdownOpen = false;
    }
}
