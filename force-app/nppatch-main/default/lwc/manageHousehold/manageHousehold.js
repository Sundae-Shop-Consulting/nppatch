import { LightningElement, wire } from "lwc";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import {
    showToast,
    reduceErrors,
    getChildObjectByName,
    prefixNamespace,
    debouncify
} from "c/util";

import getInitialData from "@salesforce/apex/HH_Container_LCTRL.getInitialData";
import getHHNamesGreetings from "@salesforce/apex/HH_Container_LCTRL.getHHNamesGreetings";
import saveHouseholdPage from "@salesforce/apex/HH_Container_LCTRL.saveHouseholdPage";
import getContactById from "@salesforce/apex/HH_Container_LCTRL.getContactById";
import getContacts from "@salesforce/apex/HH_Container_LCTRL.getContacts";
import getAddresses from "@salesforce/apex/HH_Container_LCTRL.getAddresses";
import addContactAddresses from "@salesforce/apex/HH_Container_LCTRL.addContactAddresses";

// Labels
import labelManageHousehold from "@salesforce/label/c.ManageHousehold";
import labelHouseholdMembers from "@salesforce/label/c.HouseholdMembers";
import labelHouseholdAddress from "@salesforce/label/c.HouseholdAddress";
import labelHouseholdDetails from "@salesforce/label/c.HouseholdDetails";
import stgBtnCancel from "@salesforce/label/c.stgBtnCancel";
import stgBtnSave from "@salesforce/label/c.stgBtnSave";
import lblHousehold from "@salesforce/label/c.lblHousehold";
import lblYouAreHere from "@salesforce/label/c.lblYouAreHere";
import lblDeleteContact from "@salesforce/label/c.lblDeleteContact";
import lblDeleteContactPrompt from "@salesforce/label/c.lblDeleteContactPrompt";
import btnRemove from "@salesforce/label/c.btnRemove";
import NewContact from "@salesforce/label/c.NewContact";
import ContactLastNameRqd from "@salesforce/label/c.ContactLastNameRqd";
import lblSalutation from "@salesforce/label/c.lblSalutation";
import lblFirstName from "@salesforce/label/c.lblFirstName";
import lblLastName from "@salesforce/label/c.lblLastName";
import lblMergeHHTitle from "@salesforce/label/c.lblMergeHHTitle";
import lblMergeHHPrompt from "@salesforce/label/c.lblMergeHHPrompt";
import lblBtnAddContact from "@salesforce/label/c.lblBtnAddContact";
import lblBtnAddAllHHMembers from "@salesforce/label/c.lblBtnAddAllHHMembers";
import lblNoHHMergePermissions from "@salesforce/label/c.lblNoHHMergePermissions";
import lblFindInContacts from "@salesforce/label/c.lblFindInContacts";

const NAMESPACE_PREFIX = prefixNamespace("");

export default class ManageHousehold extends NavigationMixin(LightningElement) {
    householdId;

    @wire(CurrentPageReference)
    setCurrentPageReference(pageRef) {
        if (pageRef?.state?.c__householdId) {
            this.householdId = pageRef.state.c__householdId;
        }
    }

    // State
    household = null;
    contacts = [];
    addresses = [];
    salutations = [];
    fieldLabels = {};
    fieldSetFields = [];
    allowHouseholdMerge = false;

    contactsToRemove = [];
    householdsToMerge = [];

    isAutoName = true;
    isAutoFormalGreeting = true;
    isAutoInformalGreeting = true;

    showSpinner = true;
    isLoaded = false;
    isSaveDisabled = false;
    errorMessage = "";

    // Popups
    showRemoveContactPopup = false;
    showNewContactPopup = false;
    showMergeHHPopup = false;
    contactToRemoveIndex = -1;
    contactToAdd = null;
    householdToMerge = null;
    newContact = {};
    newContactError = "";

    _debouncedUpdateNames;

    connectedCallback() {
        this._debouncedUpdateNames = debouncify(
            this._updateHHNames.bind(this),
            300
        );
    }

    // Label getters
    get manageHouseholdLabel() { return labelManageHousehold; }
    get householdMembersLabel() { return labelHouseholdMembers; }
    get householdAddressLabel() { return labelHouseholdAddress; }
    get householdDetailsLabel() { return labelHouseholdDetails; }
    get cancelLabel() { return stgBtnCancel; }
    get saveLabel() { return stgBtnSave; }
    get householdLabel() { return lblHousehold; }
    get youAreHereLabel() { return lblYouAreHere; }
    get deleteContactLabel() { return lblDeleteContact; }
    get deleteContactPromptLabel() { return lblDeleteContactPrompt; }
    get removeLabel() { return btnRemove; }
    get newContactLabel() { return NewContact; }
    get salutationLabel() { return lblSalutation; }
    get firstNameLabel() { return lblFirstName; }
    get lastNameLabel() { return lblLastName; }
    get mergeHHTitleLabel() { return lblMergeHHTitle; }
    get addAllHHMembersLabel() { return lblBtnAddAllHHMembers; }
    get noHHMergePermissionsLabel() { return lblNoHHMergePermissions; }
    get findInContactsLabel() { return lblFindInContacts; }

    get contactPickerFilter() {
        const existingIds = this.contacts
            .map((c) => c.Id)
            .filter(Boolean);
        if (existingIds.length === 0) {
            return undefined;
        }
        return {
            criteria: [
                { fieldPath: "Id", operator: "nin", value: existingIds }
            ]
        };
    }

    get householdListUrl() {
        return "/" + (this.hhTypePrefix || "001");
    }

    get householdRecordUrl() {
        return "/" + this.householdId;
    }

    get householdNameValue() {
        return this.household ? this.household.Name : "";
    }

    get formalGreetingValue() {
        return this.household
            ? getChildObjectByName(this.household, "Formal_Greeting__c") || ""
            : "";
    }

    get informalGreetingValue() {
        return this.household
            ? getChildObjectByName(this.household, "Informal_Greeting__c") || ""
            : "";
    }

    get hhTypePrefix() {
        return this.householdId
            ? String(this.householdId).substring(0, 3)
            : "";
    }

    get isHHAccount() {
        return this.hhTypePrefix === "001";
    }

    get householdObjectApiName() {
        return this.isHHAccount ? "Account" : prefixNamespace("Household__c");
    }

    get hasFieldsetFields() {
        return this.fieldSetFields && this.fieldSetFields.length > 0;
    }

    get contactUndeliverableLabel() {
        if (!this.fieldLabels) return "";
        const key = prefixNamespace("Undeliverable_Address__c");
        return this.fieldLabels[key] || getChildObjectByName(this.fieldLabels, "Undeliverable_Address__c") || "";
    }

    get addressUndeliverableLabel() {
        if (!this.fieldLabels) return "";
        const key = prefixNamespace("Undeliverable__c");
        return this.fieldLabels[key] || getChildObjectByName(this.fieldLabels, "Undeliverable__c") || "";
    }

    get salutationOptions() {
        return (this.salutations || []).map((s) => ({
            label: s.label,
            value: s.value || ""
        }));
    }

    get mergeHHPromptText() {
        if (!this.contactToAdd) return lblMergeHHPrompt;
        const name = `${this.contactToAdd.FirstName || ""} ${this.contactToAdd.LastName || ""}`.trim();
        return lblMergeHHPrompt.replaceAll("{0}", name);
    }

    get addContactButtonLabel() {
        if (!this.contactToAdd) return lblBtnAddContact;
        const name = `${this.contactToAdd.FirstName || ""} ${this.contactToAdd.LastName || ""}`.trim();
        return lblBtnAddContact.replace("{0}", name);
    }

    @wire(getInitialData, { householdId: "$householdId" })
    wiredInitialData({ error, data }) {
        if (data) {
            this.household = this._removePrefix(data.household);
            this.contacts = this._removeListPrefix(data.contacts).map(
                (c, i) => ({ ...c, _key: c.Id || `new-${i}` })
            );
            this.addresses = this._removeListPrefix(data.addresses);
            this.salutations = data.salutations;
            this.fieldLabels = this._removePrefix(data.fieldLabels);
            this.allowHouseholdMerge = data.allowHouseholdMerge;
            this.fieldSetFields = data.fieldSetFields;

            // Set auto-naming states from SYSTEM_CUSTOM_NAMING__c
            const exclusions = this.household.SYSTEM_CUSTOM_NAMING__c || "";
            this.isAutoName = !exclusions.includes("Name");
            this.isAutoFormalGreeting = !exclusions.includes("Formal_Greeting__c");
            this.isAutoInformalGreeting = !exclusions.includes("Informal_Greeting__c");

            this._initNewContact();
            this.isLoaded = true;
            this.showSpinner = false;
        } else if (error) {
            this.errorMessage = reduceErrors(error).join(", ");
            this.isSaveDisabled = true;
            this.showSpinner = false;
        }
    }

    // ===== Namespace handling =====

    _removePrefix(obj) {
        if (!obj || typeof obj !== "object") return obj;
        const result = {};
        for (const key of Object.keys(obj)) {
            if (key.startsWith(NAMESPACE_PREFIX)) {
                const newKey = key.replace(NAMESPACE_PREFIX, "");
                result[newKey] =
                    obj[key] && typeof obj[key] === "object"
                        ? this._removePrefix(obj[key])
                        : obj[key];
            } else {
                result[key] =
                    obj[key] && typeof obj[key] === "object" && !Array.isArray(obj[key])
                        ? this._removePrefix(obj[key])
                        : obj[key];
            }
        }
        return result;
    }

    _addPrefix(obj) {
        if (!obj || typeof obj !== "object") return obj;
        const result = {};
        for (const key of Object.keys(obj)) {
            if (key === "_key" || key === "dtNewContact") {
                continue;
            }
            // Custom field with single __ (no namespace yet) ending in __c
            if (
                key.endsWith("__c") &&
                key.indexOf("__") === key.lastIndexOf("__")
            ) {
                result[NAMESPACE_PREFIX + key] =
                    obj[key] && typeof obj[key] === "object"
                        ? this._addPrefix(obj[key])
                        : obj[key];
            } else if (
                key.endsWith("__r") &&
                key.indexOf("__") === key.lastIndexOf("__")
            ) {
                result[NAMESPACE_PREFIX + key] =
                    obj[key] && typeof obj[key] === "object"
                        ? this._addPrefix(obj[key])
                        : obj[key];
            } else {
                result[key] =
                    obj[key] && typeof obj[key] === "object" && !Array.isArray(obj[key])
                        ? this._addPrefix(obj[key])
                        : obj[key];
            }
        }
        return result;
    }

    _removeListPrefix(list) {
        if (!list) return [];
        return list.map((item) => this._removePrefix(item));
    }

    _addListPrefix(list) {
        if (!list) return [];
        return list.map((item) => this._addPrefix(item));
    }

    // ===== Contact handlers =====

    handleContactChanged(event) {
        const { index, field, value } = event.detail;
        this.contacts = this.contacts.map((con, i) => {
            if (i === index) {
                return { ...con, [field]: value };
            }
            return con;
        });
        this._debouncedUpdateNames();
    }

    handleContactRemoveRequest(event) {
        this.contactToRemoveIndex = event.detail.index;
        this.showRemoveContactPopup = true;
    }

    cancelRemoveContact() {
        this.showRemoveContactPopup = false;
        this.contactToRemoveIndex = -1;
    }

    doRemoveContact() {
        this.showRemoveContactPopup = false;
        const con = this.contacts[this.contactToRemoveIndex];
        if (con) {
            // Remove from household
            const removedCon = { ...con };
            if (this.isHHAccount) {
                removedCon.AccountId = null;
            } else {
                removedCon.Household__c = null;
            }
            removedCon.HHId__c = null;

            if (removedCon.Id) {
                this.contactsToRemove = [...this.contactsToRemove, removedCon];
            }

            this.contacts = this.contacts.filter(
                (_, i) => i !== this.contactToRemoveIndex
            );
            this._reindexContacts();
            this._debouncedUpdateNames();
        }
        this.contactToRemoveIndex = -1;
    }

    handleContactReorder(event) {
        const { index, direction } = event.detail;
        const newIndex = direction === "up" ? index - 1 : index + 1;
        if (newIndex < 0 || newIndex >= this.contacts.length) return;

        const reordered = [...this.contacts];
        const [moved] = reordered.splice(index, 1);
        reordered.splice(newIndex, 0, moved);
        this.contacts = reordered;
        this._reindexContacts();
        this._debouncedUpdateNames();
    }

    _reindexContacts() {
        this.contacts = this.contacts.map((con, i) => ({
            ...con,
            Household_Naming_Order__c: i
        }));
    }

    // ===== Contact search / add / merge =====

    async handleContactSelected(event) {
        const contactId = event.detail.recordId;
        if (!contactId) {
            return;
        }

        // Clear the record picker selection
        const picker = this.template.querySelector("lightning-record-picker");
        if (picker) {
            picker.clearSelection();
        }

        // Skip if contact is already in the household
        if (this.contacts.some((c) => c.Id === contactId)) {
            return;
        }

        this.showSpinner = true;
        try {
            const fullContact = await getContactById({ contactId });
            const conAdd = this._removePrefix(fullContact);
            conAdd.sobjectType = "Contact";

            let cMembers = 0;
            const hhId = conAdd.HHId__c;

            if (hhId && String(hhId).substring(0, 3) === "001") {
                const acc = conAdd.Account;
                if (acc) {
                    cMembers = getChildObjectByName(acc, "Number_of_Household_Members__c") || 0;
                }
            } else if (conAdd.Household__c) {
                const hhR = getChildObjectByName(conAdd, "Household__r");
                if (hhR) {
                    cMembers = getChildObjectByName(hhR, "Number_of_Household_Members__c") || 0;
                }
            }

            this.contactToAdd = conAdd;
            this.householdToMerge = { Id: hhId, Number_of_Household_Members__c: cMembers };

            if (!this.allowHouseholdMerge) {
                if (cMembers > 1) {
                    this._addSingleContact(conAdd);
                } else {
                    this.errorMessage = this.noHHMergePermissionsLabel;
                    this.showSpinner = false;
                }
                return;
            }

            if (!hhId) {
                this._addSingleContact(conAdd);
            } else if (cMembers === 1) {
                this._mergeHousehold(this.householdToMerge);
            } else {
                this.showSpinner = false;
                this.showMergeHHPopup = true;
            }
        } catch (error) {
            this.errorMessage = reduceErrors(error).join(", ");
            this.showSpinner = false;
        }
    }

    cancelMergeHH() {
        this.showMergeHHPopup = false;
    }

    doAddContact() {
        this.showMergeHHPopup = false;
        this._addSingleContact(this.contactToAdd);
    }

    doMergeHH() {
        this.showMergeHHPopup = false;
        this._mergeHousehold(this.householdToMerge);
    }

    _addSingleContact(conAdd) {
        this.showSpinner = true;
        const con = { ...conAdd };
        if (this.isHHAccount) {
            con.AccountId = this.householdId;
        } else {
            con.Household__c = this.householdId;
        }
        con.Household_Naming_Order__c = this.contacts.length;
        con._key = con.Id || `new-${Date.now()}`;

        // Update address to default if not override
        const addrMgr = this.template.querySelector("c-manage-hh-address-manager");
        const addrDefault = addrMgr ? addrMgr.addrDefault : null;
        if (addrDefault && !getChildObjectByName(con, "is_Address_Override__c")) {
            this._copyAddressToContact(addrDefault, con);
        }

        this.contacts = [...this.contacts, con];
        this._debouncedUpdateNames();
        this._addContactAddresses([con]);
    }

    async _mergeHousehold(hhMerge) {
        this.showSpinner = true;
        try {
            const mergedContacts = await getContacts({ householdId: hhMerge.Id });
            const unprefixed = this._removeListPrefix(mergedContacts);

            const existingCount = this.contacts.length;
            const newContacts = unprefixed.map((c, i) => {
                const con = { ...c };
                if (this.isHHAccount) {
                    con.AccountId = this.householdId;
                } else {
                    con.Household__c = this.householdId;
                }
                con.Household_Naming_Order__c = i + existingCount;
                con._key = con.Id || `merge-${i}`;
                return con;
            });

            // Update addresses for merged contacts
            const addrMgr = this.template.querySelector("c-manage-hh-address-manager");
            const addrDefault = addrMgr ? addrMgr.addrDefault : null;
            if (addrDefault) {
                newContacts.forEach((con) => {
                    if (!getChildObjectByName(con, "is_Address_Override__c")) {
                        this._copyAddressToContact(addrDefault, con);
                    }
                });
            }

            this.contacts = [...this.contacts, ...newContacts];

            // Remember merge for save
            if (this.isHHAccount) {
                this.householdsToMerge = [...this.householdsToMerge, hhMerge];
            }

            this._debouncedUpdateNames();

            // Load merged household's addresses
            const mergedAddrs = await getAddresses({
                householdId: hhMerge.Id,
                existingAddresses: this.addresses.map((a) => ({
                    ...this._stripInternalKeys(a),
                    sobjectType: "Address__c"
                }))
            });
            this.addresses = this._removeListPrefix(mergedAddrs);
        } catch (error) {
            this.errorMessage = reduceErrors(error).join(", ");
        } finally {
            this.showSpinner = false;
        }
    }

    async _addContactAddresses(newContacts) {
        try {
            const cleanContacts = newContacts.map(c => this._stripInternalKeys({ ...c }));
            const cleanAddresses = this.addresses.map(
                (a) => ({
                    ...this._stripInternalKeys(a),
                    sobjectType: "Address__c"
                })
            );

            const result = await addContactAddresses({
                listCon: cleanContacts,
                listAddrExisting: cleanAddresses
            });
            this.addresses = this._removeListPrefix(result);
        } catch (error) {
            console.error("Error adding contact addresses:", error);
        } finally {
            this.showSpinner = false;
        }
    }

    // ===== New Contact =====

    handleNewContactClick() {
        this.newContactError = "";
        this.showNewContactPopup = true;
    }

    cancelNewContact() {
        this.showNewContactPopup = false;
        this.newContactError = "";
    }

    handleNewContactSalutationChange(event) {
        this.newContact = { ...this.newContact, Salutation: event.detail.value || null };
    }

    handleNewContactFirstNameChange(event) {
        this.newContact = { ...this.newContact, FirstName: event.target.value };
    }

    handleNewContactLastNameChange(event) {
        this.newContact = { ...this.newContact, LastName: event.target.value };
    }

    doCreateNewContact() {
        if (!this.newContact.LastName) {
            this.newContactError = ContactLastNameRqd;
            return;
        }

        const con = { ...this.newContact };
        con.sobjectType = "Contact";
        if (this.isHHAccount) {
            con.AccountId = this.householdId;
        } else {
            con.Household__c = this.householdId;
        }
        con.HHId__c = this.householdId;
        con.dtNewContact = Date.now();
        con._key = `new-${Date.now()}`;

        // Copy default address
        const addrMgr = this.template.querySelector("c-manage-hh-address-manager");
        const addrDefault = addrMgr ? addrMgr.addrDefault : null;
        if (addrDefault) {
            this._copyAddressToContact(addrDefault, con);
        }

        con.Household_Naming_Order__c = this.contacts.length;
        this.contacts = [...this.contacts, con];

        this._initNewContact();
        this.showNewContactPopup = false;
        this._debouncedUpdateNames();
    }

    _initNewContact() {
        this.newContact = {
            sobjectType: "Contact",
            FirstName: "",
            LastName: "",
            Salutation: null
        };
        if (this.isHHAccount) {
            this.newContact.AccountId = this.householdId;
        } else {
            this.newContact.Household__c = this.householdId;
        }
        this.newContact.HHId__c = this.householdId;
    }

    // ===== Address =====

    handleAddressChanged(event) {
        const { address, addresses } = event.detail;
        this.addresses = addresses;
        this._updateDefaultAddress(address);
    }

    _updateDefaultAddress(addr) {
        if (!addr) return;

        // Update household
        const hh = { ...this.household };
        if (this.isHHAccount) {
            hh.BillingStreet = addr.MailingStreet__c || "";
            if (addr.MailingStreet2__c) {
                hh.BillingStreet += "\n" + addr.MailingStreet2__c;
            }
            hh.BillingCity = addr.MailingCity__c || "";
            hh.BillingState = addr.MailingState__c || "";
            hh.BillingPostalCode = addr.MailingPostalCode__c || "";
            hh.BillingCountry = addr.MailingCountry__c || "";
            hh.Undeliverable_Address__c =
                addr.Undeliverable__c === undefined ? false : addr.Undeliverable__c;
        } else {
            hh.MailingStreet__c = addr.MailingStreet__c || "";
            if (addr.MailingStreet2__c) {
                hh.MailingStreet__c += "," + addr.MailingStreet2__c;
            }
            hh.MailingCity__c = addr.MailingCity__c || "";
            hh.MailingState__c = addr.MailingState__c || "";
            hh.MailingPostalCode__c = addr.MailingPostalCode__c || "";
            hh.MailingCountry__c = addr.MailingCountry__c || "";
        }
        this.household = hh;

        // Update contacts without address override
        this.contacts = this.contacts.map((con) => {
            if (!getChildObjectByName(con, "is_Address_Override__c")) {
                const updated = { ...con };
                this._copyAddressToContact(addr, updated);
                return updated;
            }
            return con;
        });
    }

    _copyAddressToContact(addr, con) {
        con.MailingStreet = addr.MailingStreet__c || "";
        if (addr.MailingStreet2__c) {
            con.MailingStreet += "\n" + addr.MailingStreet2__c;
        }
        con.MailingCity = addr.MailingCity__c || "";
        con.MailingState = addr.MailingState__c || "";
        con.MailingPostalCode = addr.MailingPostalCode__c || "";
        con.MailingCountry = addr.MailingCountry__c || "";
        if (
            con.hasOwnProperty("Undeliverable_Address__c") &&
            addr.hasOwnProperty("Undeliverable__c")
        ) {
            con.Undeliverable_Address__c =
                addr.Undeliverable__c === undefined ? false : addr.Undeliverable__c;
        }
    }

    // ===== Names & Greetings =====

    handleNameChanged(event) {
        const { field, value } = event.detail;
        this.household = { ...this.household, [field]: value };

        // Turn off auto-naming for the changed field
        if (field === "Name") this.isAutoName = false;
        else if (field === "Formal_Greeting__c") this.isAutoFormalGreeting = false;
        else if (field === "Informal_Greeting__c") this.isAutoInformalGreeting = false;
    }

    handleAutoNamingChanged(event) {
        const { field, checked } = event.detail;
        if (field === "Name") this.isAutoName = checked;
        else if (field === "Formal_Greeting__c") this.isAutoFormalGreeting = checked;
        else if (field === "Informal_Greeting__c") this.isAutoInformalGreeting = checked;

        if (checked) {
            this._debouncedUpdateNames();
        }
    }

    _updateNamingExclusions() {
        let exclusions = "";
        if (!this.isAutoName) exclusions += "Name;";
        if (!this.isAutoFormalGreeting) exclusions += "Formal_Greeting__c;";
        if (!this.isAutoInformalGreeting) exclusions += "Informal_Greeting__c;";
        this.household = {
            ...this.household,
            SYSTEM_CUSTOM_NAMING__c: exclusions
        };
    }

    async _updateHHNames() {
        try {
            this._updateNamingExclusions();

            // Strip internal keys but do NOT add namespace prefix.
            // The Lightning framework resolves namespace automatically for
            // same-namespace LWC-to-Apex calls.
            const hhClean = this._stripInternalKeys({ ...this.household });
            const conClean = this.contacts.map(c => this._stripInternalKeys({ ...c }));

            const result = await getHHNamesGreetings({
                hh: hhClean,
                listCon: conClean
            });

            // Merge naming fields from result into existing household
            this.household = {
                ...this.household,
                Name: result.Name,
                Formal_Greeting__c: result.Formal_Greeting__c,
                Informal_Greeting__c: result.Informal_Greeting__c
            };
        } catch (error) {
            const msg = reduceErrors(error).join(", ");
            console.error("[ManageHH] Error updating names:", msg, error);
            this.errorMessage = "Naming update error: " + msg;
        }
    }

    _stripInternalKeys(obj) {
        const result = { ...obj };
        delete result._key;
        delete result.dtNewContact;
        return result;
    }

    // ===== Save =====

    async handleSave() {
        this.showSpinner = true;
        this.errorMessage = "";

        try {
            this._updateNamingExclusions();

            const hh = this._stripInternalKeys({ ...this.household });
            hh.Number_of_Household_Members__c = this.contacts.length;

            const conClean = this.contacts.map(c => this._stripInternalKeys({ ...c }));
            const conRemoveClean = this.contactsToRemove.map(c => this._stripInternalKeys({ ...c }));
            const hhMergeClean =
                this.householdsToMerge.length > 0
                    ? this.householdsToMerge.map(h => this._stripInternalKeys({ ...h }))
                    : null;

            // Also save fieldset fields via record-edit-form
            const recordEditForm = this.template.querySelector(
                "lightning-record-edit-form"
            );
            if (recordEditForm) {
                recordEditForm.submit();
            }

            await saveHouseholdPage({
                hh: hh,
                listCon: conClean,
                listConRemove: conRemoveClean,
                listHHMerge: hhMergeClean
            });

            this._closePage();
        } catch (error) {
            this.showSpinner = false;
            this.errorMessage = reduceErrors(error).join(", ");
            showToast(this, "Error", this.errorMessage, "error");
        }
    }

    handleFieldsetSaveSuccess() {
        // Fieldset saved - page close handled by main save
    }

    handleFieldsetSaveError(event) {
        this.showSpinner = false;
        this.errorMessage = event.detail.message || "Error saving fieldset fields";
    }

    handleCancel() {
        this._closePage();
    }

    _closePage() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.householdId,
                actionName: "view"
            }
        });
    }
}
