import { LightningElement, track } from "lwc";
import getBatches from "@salesforce/apex/BDI_ImportWizardController.getBatches";
import processBatch from "@salesforce/apex/BDI_ImportWizardController.processBatch";

export default class BdiBatchDashboard extends LightningElement {
    @track batches = [];
    isLoading = false;

    connectedCallback() {
        this._loadBatches();
    }

    get hasBatches() {
        return this.batches.length > 0;
    }

    get batchCards() {
        return this.batches.map((b) => ({
            ...b,
            key: b.Id,
            statusClass: "status-badge " + this._statusBadgeClass(b.Status),
            createdDateFormatted: b.CreatedDate
                ? new Date(b.CreatedDate).toLocaleDateString()
                : "",
            lastProcessedFormatted: b.LastProcessedOn
                ? new Date(b.LastProcessedOn).toLocaleString()
                : "Never",
            hasFailures: b.RecordsFailed > 0,
            hasPending: b.PendingRecords > 0,
        }));
    }

    handleRefresh() {
        this._loadBatches();
    }

    handleViewBatch(event) {
        const batchId = event.currentTarget.dataset.id;
        window.open("/" + batchId, "_blank");
    }

    async handleProcessBatch(event) {
        const batchId = event.currentTarget.dataset.id;
        this.isLoading = true;
        try {
            await processBatch({ batchId, isDryRun: false });
            await this._loadBatches();
        } catch (e) {
            console.error("Process batch error", e);
        } finally {
            this.isLoading = false;
        }
    }

    async _loadBatches() {
        this.isLoading = true;
        try {
            this.batches = await getBatches({ statusFilter: "All" });
        } catch (e) {
            console.error("Error loading batches", e);
        } finally {
            this.isLoading = false;
        }
    }

    _statusBadgeClass(status) {
        if (status === "Completed") return "completed";
        if (status === "Open") return "open";
        return "failed";
    }
}
