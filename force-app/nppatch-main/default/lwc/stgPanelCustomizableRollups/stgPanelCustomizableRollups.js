import { LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getCurrentNamespace } from "c/utilCommon";

export default class StgPanelCustomizableRollups extends NavigationMixin(LightningElement) {
    handleOpenCRLP() {
        const ns = getCurrentNamespace();
        const prefix = ns ? ns + "__" : "";
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: window.location.origin + "/apex/" + prefix + "CRLP_RollupSetup",
            },
        });
    }
}
