import { createElement } from "lwc";
import StgPanelMembership from "c/stgPanelMembership";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";
import saveSettings from "@salesforce/apex/NppatchSettingsController.saveSettings";
import getRecordTypeOptions from "@salesforce/apex/NppatchSettingsController.getRecordTypeOptions";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

jest.mock(
    "@salesforce/apex/NppatchSettingsController.getSettings",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/NppatchSettingsController.saveSettings",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/NppatchSettingsController.getRecordTypeOptions",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/NppatchSettingsController.isAdmin",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

// Mock labels
jest.mock("@salesforce/label/c.stgNavDonations", () => ({ default: "Donations" }), { virtual: true });
jest.mock("@salesforce/label/c.stgNavMembership", () => ({ default: "Membership" }), { virtual: true });
jest.mock("@salesforce/label/c.stgHelpMembershipRT", () => ({ default: "Help text for RT" }), { virtual: true });
jest.mock("@salesforce/label/c.stgHelpMembershipGracePeriod", () => ({ default: "Help text for grace period" }), {
    virtual: true,
});
jest.mock("@salesforce/label/c.stgBtnEdit", () => ({ default: "Edit" }), { virtual: true });
jest.mock("@salesforce/label/c.stgBtnSave", () => ({ default: "Save" }), { virtual: true });
jest.mock("@salesforce/label/c.stgBtnCancel", () => ({ default: "Cancel" }), { virtual: true });
jest.mock("@salesforce/label/c.stgLabelNone", () => ({ default: "None" }), { virtual: true });

const MOCK_HOUSEHOLDS_SETTINGS = {
    Id: "a00000000000001",
    Membership_Record_Types__c: "012000000000001;012000000000002",
    Membership_Grace_Period__c: 30,
};

const MOCK_CRLP_SETTINGS = {
    Id: "a00000000000002",
    Customizable_Rollups_Enabled__c: false,
};

const MOCK_RECORD_TYPE_OPTIONS = [
    { label: "Donation", value: "012000000000001" },
    { label: "Membership", value: "012000000000002" },
    { label: "Grant", value: "012000000000003" },
];

describe("c-stg-panel-membership", () => {
    beforeEach(() => {
        getSettings.mockImplementation((params) => {
            if (params.settingsObjectName === "Households_Settings__c") {
                return Promise.resolve(MOCK_HOUSEHOLDS_SETTINGS);
            }
            if (params.settingsObjectName === "Customizable_Rollup_Settings__c") {
                return Promise.resolve(MOCK_CRLP_SETTINGS);
            }
            return Promise.resolve({});
        });
        getRecordTypeOptions.mockResolvedValue(MOCK_RECORD_TYPE_OPTIONS);
        saveSettings.mockResolvedValue(undefined);
        isAdmin.mockResolvedValue(true);
    });

    afterEach(() => {
        clearDOM();
    });

    it("renders in read-only mode by default", async () => {
        const element = createElement("c-stg-panel-membership", { is: StgPanelMembership });
        document.body.appendChild(element);
        await flushPromises();

        const dualListbox = element.shadowRoot.querySelector("lightning-dual-listbox");
        expect(dualListbox).toBeNull();
    });

    it("displays current grace period value", async () => {
        const element = createElement("c-stg-panel-membership", { is: StgPanelMembership });
        document.body.appendChild(element);
        await flushPromises();

        const valueElements = element.shadowRoot.querySelectorAll(".setting-value");
        const hasGracePeriod = Array.from(valueElements).some((el) => el.textContent === "30");
        expect(hasGracePeriod).toBe(true);
    });

    it("shows Edit button for admin users", async () => {
        const element = createElement("c-stg-panel-membership", { is: StgPanelMembership });
        document.body.appendChild(element);
        await flushPromises();

        const editButton = element.shadowRoot.querySelector("lightning-button");
        expect(editButton).toBeTruthy();
        expect(editButton.label).toBe("Edit");
    });

    it("hides Edit button for non-admin users", async () => {
        isAdmin.mockResolvedValue(false);

        const element = createElement("c-stg-panel-membership", { is: StgPanelMembership });
        document.body.appendChild(element);
        await flushPromises();

        const editButton = element.shadowRoot.querySelector("lightning-button");
        expect(editButton).toBeNull();
    });

    it("enters edit mode when Edit button is clicked", async () => {
        const element = createElement("c-stg-panel-membership", { is: StgPanelMembership });
        document.body.appendChild(element);
        await flushPromises();

        const editButton = element.shadowRoot.querySelector("lightning-button");
        editButton.click();
        await flushPromises();

        const numberInput = element.shadowRoot.querySelector('lightning-input[type="number"]');
        expect(numberInput).toBeTruthy();
    });

    it("calls saveSettings on Save click", async () => {
        const element = createElement("c-stg-panel-membership", { is: StgPanelMembership });
        document.body.appendChild(element);
        await flushPromises();

        // Enter edit mode
        const editButton = element.shadowRoot.querySelector("lightning-button");
        editButton.click();
        await flushPromises();

        // Click Save
        const buttons = element.shadowRoot.querySelectorAll("lightning-button");
        const saveButton = Array.from(buttons).find((btn) => btn.label === "Save");
        saveButton.click();
        await flushPromises();

        expect(saveSettings).toHaveBeenCalledWith(
            expect.objectContaining({
                settingsObjectName: "Households_Settings__c",
            })
        );
    });

    it("reverts changes on Cancel click", async () => {
        const element = createElement("c-stg-panel-membership", { is: StgPanelMembership });
        document.body.appendChild(element);
        await flushPromises();

        // Enter edit mode
        const editButton = element.shadowRoot.querySelector("lightning-button");
        editButton.click();
        await flushPromises();

        // Click Cancel
        const buttons = element.shadowRoot.querySelectorAll("lightning-button");
        const cancelButton = Array.from(buttons).find((btn) => btn.label === "Cancel");
        cancelButton.click();
        await flushPromises();

        // Should be back in read-only mode
        const numberInput = element.shadowRoot.querySelector('lightning-input[type="number"]');
        expect(numberInput).toBeNull();
    });
});
