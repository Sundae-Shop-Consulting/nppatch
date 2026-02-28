import { LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getCurrentNamespace } from "c/utilCommon";

export default class StgPanelAdvancedMapping extends NavigationMixin(LightningElement) {
    handleOpenMapping() {
        const ns = getCurrentNamespace();
        const prefix = ns ? ns + "__" : "c__";
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: window.location.origin + "/lightning/cmp/" + prefix + "BDI_ManageAdvancedMapping",
            },
        });
    }
}
