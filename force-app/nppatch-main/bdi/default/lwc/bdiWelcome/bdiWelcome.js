import { LightningElement, track } from "lwc";
import getBatches from "@salesforce/apex/BDI_ImportWizardController.getBatches";

export default class BdiWelcome extends LightningElement {
    @track stats = {
        openBatches: 0,
        pendingRecords: 0,
        failedRecords: 0,
    };

    async connectedCallback() {
        try {
            const batches = await getBatches({ statusFilter: "All" });
            let openBatches = 0;
            let pendingRecords = 0;
            let failedRecords = 0;

            batches.forEach((b) => {
                if (b.Status === "Open") openBatches++;
                pendingRecords += b.PendingRecords || 0;
                failedRecords += b.RecordsFailed || 0;
            });

            this.stats = { openBatches, pendingRecords, failedRecords };
        } catch (e) {
            console.error("Error loading stats", e);
        }
    }

    get hasFailures() {
        return this.stats.failedRecords > 0;
    }
}
