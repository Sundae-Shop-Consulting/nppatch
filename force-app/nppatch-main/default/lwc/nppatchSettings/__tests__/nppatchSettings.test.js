import { createElement } from "lwc";
import NppatchSettings from "c/nppatchSettings";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";
import ensureSettingsExist from "@salesforce/apex/NppatchSettingsController.ensureSettingsExist";

jest.mock(
    "@salesforce/apex/NppatchSettingsController.isAdmin",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/NppatchSettingsController.ensureSettingsExist",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

jest.mock("@salesforce/label/c.stgNPPatchSettingsTitle", () => ({ default: "NPPatch Settings" }), { virtual: true });
jest.mock("@salesforce/label/c.commonInsufficientPermissions", () => ({ default: "Insufficient Permissions" }), { virtual: true });
jest.mock("@salesforce/label/c.addrCopyConAddBtnFls", () => ({ default: "Access denied" }), { virtual: true });

describe("c-nppatch-settings", () => {
    beforeEach(() => {
        isAdmin.mockResolvedValue(true);
        ensureSettingsExist.mockResolvedValue(undefined);
    });

    afterEach(() => {
        clearDOM();
    });

    it("renders navigation with all six groups when user is admin", async () => {
        const element = createElement("c-nppatch-settings", { is: NppatchSettings });
        document.body.appendChild(element);
        await flushPromises();

        const sections = element.shadowRoot.querySelectorAll(
            "lightning-vertical-navigation-section"
        );
        expect(sections.length).toBe(6);
    });

    it("renders membership panel by default", async () => {
        const element = createElement("c-nppatch-settings", { is: NppatchSettings });
        document.body.appendChild(element);
        await flushPromises();

        const membershipPanel = element.shadowRoot.querySelector("c-stg-panel-membership");
        expect(membershipPanel).toBeTruthy();
    });

    it("shows insufficient permissions when user is not admin", async () => {
        isAdmin.mockResolvedValue(false);

        const element = createElement("c-nppatch-settings", { is: NppatchSettings });
        document.body.appendChild(element);
        await flushPromises();

        const illustration = element.shadowRoot.querySelector("c-util-illustration");
        expect(illustration).toBeTruthy();
    });

    it("shows placeholder when an unimplemented nav item is selected", async () => {
        const element = createElement("c-nppatch-settings", { is: NppatchSettings });
        document.body.appendChild(element);
        await flushPromises();

        const nav = element.shadowRoot.querySelector("lightning-vertical-navigation");
        nav.dispatchEvent(new CustomEvent("select", { detail: { name: "healthCheck" } }));
        await flushPromises();

        const membershipPanel = element.shadowRoot.querySelector("c-stg-panel-membership");
        expect(membershipPanel).toBeNull();
    });
});
