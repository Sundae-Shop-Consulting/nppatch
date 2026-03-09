import { LightningElement } from "lwc";
import { getCurrentNamespace } from "c/utilCommon";

export default class StgPanelAdvancedMapping extends LightningElement {
    handleOpenMapping() {
        const ns = getCurrentNamespace();
        const prefix = ns ? ns + "__" : "c__";
        window.open("/lightning/cmp/" + prefix + "BDI_ManageAdvancedMapping", "_blank");
    }
}
