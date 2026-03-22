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

jest.mock("c/settingsModal", () => ({ default: { open: jest.fn() } }), { virtual: true });

jest.mock("@salesforce/label/c.stgNPPatchSettingsTitle", () => ({ default: "NPPatch Settings" }), { virtual: true });
jest.mock("@salesforce/label/c.commonInsufficientPermissions", () => ({ default: "Insufficient Permissions" }), {
    virtual: true,
});
jest.mock("@salesforce/label/c.addrCopyConAddBtnFls", () => ({ default: "Access denied" }), { virtual: true });

describe("c-nppatch-settings", () => {
    beforeEach(() => {
        isAdmin.mockResolvedValue(true);
        ensureSettingsExist.mockResolvedValue(undefined);
    });

    afterEach(() => {
        clearDOM();
    });

    it("renders tile grid with all five groups when user is admin", async () => {
        const element = createElement("c-nppatch-settings", { is: NppatchSettings });
        document.body.appendChild(element);
        await flushPromises();

        const groupHeadings = element.shadowRoot.querySelectorAll(".group-heading");
        expect(groupHeadings.length).toBe(5);
    });

    it("shows insufficient permissions when user is not admin", async () => {
        isAdmin.mockResolvedValue(false);

        const element = createElement("c-nppatch-settings", { is: NppatchSettings });
        document.body.appendChild(element);
        await flushPromises();

        const illustration = element.shadowRoot.querySelector("c-util-illustration");
        expect(illustration).toBeTruthy();
    });

    it("renders settings tiles with icon buttons", async () => {
        const element = createElement("c-nppatch-settings", { is: NppatchSettings });
        document.body.appendChild(element);
        await flushPromises();

        const iconBtns = element.shadowRoot.querySelectorAll("lightning-button-icon");
        expect(iconBtns.length).toBeGreaterThan(0);
    });
});
