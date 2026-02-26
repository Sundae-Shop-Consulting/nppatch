import { createElement } from "lwc";
import RelationshipsNavigator from "c/relationshipsNavigator";
import getContactName from "@salesforce/apex/RelationshipsTreeGridController.getContactName";
import getInitialView from "@salesforce/apex/RelationshipsTreeGridController.getInitialView";

const mockGetInitialView = require("../../relationshipsTreeGrid/__tests__/data/mockGetInitialView.json");
const FAKE_CONTACT_ID = "003_FAKE_CONTACT_ID";
const FAKE_CONTACT_NAME = "FakeFirstName FakeLastName";

jest.mock(
    "@salesforce/apex/RelationshipsTreeGridController.getContactName",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/RelationshipsTreeGridController.getInitialView",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

describe("c-relationships-navigator", () => {
    beforeEach(() => {
        getContactName.mockResolvedValue(FAKE_CONTACT_NAME);
        getInitialView.mockResolvedValue(mockGetInitialView);
    });

    afterEach(() => {
        clearDOM();
    });

    it("loads a card with a contact name", async () => {
        const element = createElement("c-relationships-navigator", { is: RelationshipsNavigator });
        element.recordId = FAKE_CONTACT_ID;

        document.body.appendChild(element);
        await flushPromises();

        const cardCmp = element.shadowRoot.querySelector("lightning-card");
        expect(cardCmp.title).toBe(FAKE_CONTACT_NAME);
    });

    it("displays an error when user does not have access", async () => {
        const errorMessage = {
            status: 500,
            body: {
                message: "Insufficient Permissions",
            },
        };
        getInitialView.mockRejectedValue(errorMessage);

        const element = createElement("c-relationships-navigator", { is: RelationshipsNavigator });
        element.recordId = FAKE_CONTACT_ID;
        document.body.appendChild(element);
        await flushPromises();

        const errorMessageCmp = element.shadowRoot.querySelector("c-util-illustration");
        expect(errorMessageCmp).toBeTruthy();
    });

    it("does not render tree grid until tabular tab is activated", async () => {
        const element = createElement("c-relationships-navigator", { is: RelationshipsNavigator });
        element.recordId = FAKE_CONTACT_ID;

        document.body.appendChild(element);
        await flushPromises();

        expect(element.shadowRoot.querySelector("c-relationships-tree-grid")).toBeNull();
    });

    it("passes isLightningOut value down to tree grid component after tab activation", async () => {
        const element = createElement("c-relationships-navigator", { is: RelationshipsNavigator });
        element.recordId = FAKE_CONTACT_ID;
        element.isLightningOut = true;

        document.body.appendChild(element);
        await flushPromises();

        // Simulate tabular tab becoming active
        const tabularTab = element.shadowRoot.querySelectorAll("lightning-tab")[1];
        tabularTab.dispatchEvent(new CustomEvent("active"));
        await flushPromises();

        const treeGrid = element.shadowRoot.querySelector("c-relationships-tree-grid");
        expect(treeGrid).toBeTruthy();
        expect(treeGrid.isLightningOut).toBe(true);
    });
});
