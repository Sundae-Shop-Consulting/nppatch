import { LightningElement, track } from "lwc";
import getFieldCategories from "@salesforce/apex/BDI_ImportWizardController.getFieldCategories";
import getDefaultBatchSettings from "@salesforce/apex/BDI_ImportWizardController.getDefaultBatchSettings";
import createBatchWithRecords from "@salesforce/apex/BDI_ImportWizardController.createBatchWithRecords";
import processBatch from "@salesforce/apex/BDI_ImportWizardController.processBatch";
import getProcessingStatus from "@salesforce/apex/BDI_ImportWizardController.getProcessingStatus";
import BdiBatchConfigModal from "c/bdiBatchConfigModal";

const STEP_UPLOAD = "upload";
const STEP_MAP = "map";
const STEP_REVIEW = "review";
const STEP_PROCESSING = "processing";

export default class BdiImportWizard extends LightningElement {
    currentStep = STEP_UPLOAD;

    // Upload state
    fileName = "";
    csvHeaders = [];
    csvRows = [];
    previewRows = [];

    // Field mapping state
    @track fieldCategories = [];
    @track fieldMapping = {};
    allTargetFields = [];

    // Batch config
    batchName = "";
    batchDescription = "";
    isDryRun = false;
    @track batchConfig = {};

    // Import results
    @track importResult = {};
    batchId;
    jobId;

    // Processing state
    @track processingStatus = {};
    isPolling = false;

    // Loading
    isLoading = false;

    // Step indicators
    get steps() {
        return [
            {
                label: "Upload CSV",
                value: STEP_UPLOAD,
                class: this._stepClass(STEP_UPLOAD),
            },
            {
                label: "Map Fields",
                value: STEP_MAP,
                class: this._stepClass(STEP_MAP),
            },
            {
                label: "Review & Import",
                value: STEP_REVIEW,
                class: this._stepClass(STEP_REVIEW),
            },
            {
                label: "Processing",
                value: STEP_PROCESSING,
                class: this._stepClass(STEP_PROCESSING),
            },
        ];
    }

    connectedCallback() {
        this._loadDefaultConfig();
    }

    async _loadDefaultConfig() {
        try {
            this.batchConfig = await getDefaultBatchSettings();
        } catch (e) {
            console.error("Error loading default batch settings", e);
        }
    }

    async handleOpenBatchConfig() {
        const result = await BdiBatchConfigModal.open({
            size: "medium",
            config: { ...this.batchConfig },
        });
        if (result) {
            this.batchConfig = result;
        }
    }

    get isUploadStep() {
        return this.currentStep === STEP_UPLOAD;
    }
    get isMapStep() {
        return this.currentStep === STEP_MAP;
    }
    get isReviewStep() {
        return this.currentStep === STEP_REVIEW;
    }
    get isProcessingStep() {
        return this.currentStep === STEP_PROCESSING;
    }

    get hasFile() {
        return this.csvHeaders.length > 0;
    }
    get rowCount() {
        return this.csvRows.length;
    }
    get previewData() {
        return this.previewRows.map((row, rowIdx) => ({
            key: "row-" + rowIdx,
            cells: this.csvHeaders.map((header) => ({
                key: header,
                value: row[header] || "",
            })),
        }));
    }
    get mappedFieldCount() {
        return Object.values(this.fieldMapping).filter((v) => v).length;
    }
    get unmappedHeaders() {
        return this.csvHeaders.filter((h) => !this.fieldMapping[h]);
    }
    get hasUnmappedHeaders() {
        return this.unmappedHeaders.length > 0;
    }
    get canImport() {
        return this.mappedFieldCount > 0 && this.batchName;
    }
    get mapNextDisabled() {
        return !this.mappedFieldCount;
    }
    get importDisabled() {
        return !this.canImport;
    }

    get progressPercent() {
        const s = this.processingStatus;
        if (s.totalJobItems > 0) {
            return Math.round((s.jobItemsProcessed / s.totalJobItems) * 100);
        }
        return 0;
    }
    get isJobComplete() {
        const status = this.processingStatus.jobStatus;
        return (
            status === "Completed" ||
            status === "Failed" ||
            status === "Aborted"
        );
    }
    get isJobFailed() {
        return this.processingStatus.jobStatus === "Failed";
    }
    get processingStatusLabel() {
        if (this.isJobComplete) {
            return this.isJobFailed ? "Failed" : "Complete";
        }
        return "Processing...";
    }
    get statusCounts() {
        const counts = this.processingStatus.statusCounts || {};
        return Object.entries(counts).map(([status, count]) => ({
            key: status,
            status,
            count,
        }));
    }

    // ---- Upload step ----

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        this.fileName = file.name;
        this.batchName = file.name.replace(/\.csv$/i, "");
        const reader = new FileReader();

        reader.onload = () => {
            const text = reader.result;
            this._parseCsv(text);
        };

        reader.readAsText(file);
    }

    _parseCsv(text) {
        // Handle BOM
        const cleaned = text.charCodeAt(0) === 0xfeff ? text.slice(1) : text;
        const rows = this._csvToRows(cleaned);

        if (rows.length < 2) {
            this.csvHeaders = [];
            this.csvRows = [];
            return;
        }

        this.csvHeaders = rows[0];
        this.csvRows = [];

        for (let i = 1; i < rows.length; i++) {
            if (rows[i].every((cell) => cell === "")) continue;
            const rowObj = {};
            this.csvHeaders.forEach((header, idx) => {
                rowObj[header] = rows[i][idx] || "";
            });
            this.csvRows.push(rowObj);
        }

        this.previewRows = this.csvRows.slice(0, 5);
    }

    _csvToRows(text) {
        const rows = [];
        let current = [];
        let cell = "";
        let inQuotes = false;

        for (let i = 0; i < text.length; i++) {
            const ch = text[i];
            const next = text[i + 1];

            if (inQuotes) {
                if (ch === '"' && next === '"') {
                    cell += '"';
                    i++;
                } else if (ch === '"') {
                    inQuotes = false;
                } else {
                    cell += ch;
                }
            } else {
                if (ch === '"') {
                    inQuotes = true;
                } else if (ch === ",") {
                    current.push(cell.trim());
                    cell = "";
                } else if (ch === "\n" || (ch === "\r" && next === "\n")) {
                    current.push(cell.trim());
                    rows.push(current);
                    current = [];
                    cell = "";
                    if (ch === "\r") i++;
                } else {
                    cell += ch;
                }
            }
        }

        // Last cell/row
        if (cell || current.length > 0) {
            current.push(cell.trim());
            rows.push(current);
        }

        return rows;
    }

    handleUploadNext() {
        this.currentStep = STEP_MAP;
        this._loadFieldCategories();
    }

    // ---- Map step ----

    async _loadFieldCategories() {
        if (this.allTargetFields.length > 0) return;

        this.isLoading = true;
        try {
            const categories = await getFieldCategories();
            this.fieldCategories = Object.entries(categories).map(
                ([category, fields]) => ({
                    category,
                    fields: fields.sort((a, b) =>
                        a.label.localeCompare(b.label)
                    ),
                })
            );

            // Build flat list for combobox options
            const options = [{ label: "-- Do not import --", value: "" }];
            this.fieldCategories.forEach(({ category, fields }) => {
                fields.forEach((f) => {
                    options.push({
                        label: `${f.label} (${f.value}) — ${category}`,
                        value: f.value,
                    });
                });
            });
            this.allTargetFields = options;

            // Auto-match by API name or label
            this._autoMatch();
        } catch (e) {
            console.error("Error loading field categories", e);
        } finally {
            this.isLoading = false;
        }
    }

    _autoMatch() {
        const mapping = {};
        const allFields = [];
        this.fieldCategories.forEach(({ fields }) => {
            fields.forEach((f) => allFields.push(f));
        });

        this.csvHeaders.forEach((header) => {
            const normalized = header
                .replace(/\s+/g, "_")
                .replace(/[^a-zA-Z0-9_]/g, "");

            // Exact API name match
            let match = allFields.find(
                (f) => f.value.toLowerCase() === normalized.toLowerCase()
            );
            if (!match) {
                match = allFields.find(
                    (f) =>
                        f.value.toLowerCase() ===
                        normalized.toLowerCase() + "__c"
                );
            }
            // Label match
            if (!match) {
                match = allFields.find(
                    (f) =>
                        f.label.toLowerCase() ===
                        header.trim().toLowerCase()
                );
            }

            mapping[header] = match ? match.value : "";
        });

        this.fieldMapping = { ...mapping };
    }

    get mappingRows() {
        return this.csvHeaders.map((header) => ({
            header,
            key: header,
            selectedField: this.fieldMapping[header] || "",
            sampleValues: this.previewRows
                .map((r) => r[header])
                .filter((v) => v)
                .slice(0, 3)
                .join(", "),
        }));
    }

    get targetFieldOptions() {
        return this.allTargetFields;
    }

    handleMappingChange(event) {
        const header = event.target.dataset.header;
        const value = event.detail.value;
        this.fieldMapping = { ...this.fieldMapping, [header]: value };
    }

    handleMapBack() {
        this.currentStep = STEP_UPLOAD;
    }

    handleMapNext() {
        this.currentStep = STEP_REVIEW;
    }

    // ---- Review step ----

    get reviewMappings() {
        return this.csvHeaders
            .filter((h) => this.fieldMapping[h])
            .map((h) => {
                const field = this.allTargetFields.find(
                    (f) => f.value === this.fieldMapping[h]
                );
                return {
                    key: h,
                    csvHeader: h,
                    targetField: field ? field.label : this.fieldMapping[h],
                };
            });
    }

    handleBatchNameChange(event) {
        this.batchName = event.target.value;
    }
    handleBatchDescChange(event) {
        this.batchDescription = event.target.value;
    }
    handleReviewBack() {
        this.currentStep = STEP_MAP;
    }

    handleDryRun() {
        this._doImport(true);
    }

    handleImport() {
        this._doImport(false);
    }

    async _doImport(isDryRun) {
        if (!this.canImport) return;

        this.isLoading = true;
        this.isDryRun = isDryRun;
        try {
            // Filter out unmapped fields
            const cleanMapping = {};
            for (const [header, field] of Object.entries(this.fieldMapping)) {
                if (field) cleanMapping[header] = field;
            }

            this.importResult = await createBatchWithRecords({
                batchName: this.batchName,
                batchDescription: this.batchDescription,
                rowsJson: JSON.stringify(this.csvRows),
                fieldMapJson: JSON.stringify(cleanMapping),
                batchConfigJson: JSON.stringify(this.batchConfig),
            });

            this.batchId = this.importResult.batchId;

            // Auto-process
            this.jobId = await processBatch({
                batchId: this.batchId,
                isDryRun,
            });

            this.currentStep = STEP_PROCESSING;
            this._startPolling();
        } catch (e) {
            console.error("Import error", e);
            this.importResult = {
                ...this.importResult,
                error: e.body ? e.body.message : e.message,
            };
        } finally {
            this.isLoading = false;
        }
    }

    // ---- Processing step ----

    _startPolling() {
        this.isPolling = true;
        this._poll();
    }

    async _poll() {
        if (!this.isPolling) return;
        try {
            this.processingStatus = await getProcessingStatus({
                batchId: this.batchId,
                jobId: this.jobId,
            });
            if (this.isJobComplete) {
                this.isPolling = false;
                return;
            }
        } catch (e) {
            console.error("Polling error", e);
        }

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => this._poll(), 3000);
    }

    handleViewBatch() {
        window.open("/" + this.batchId, "_blank");
    }

    handleStartOver() {
        this.currentStep = STEP_UPLOAD;
        this.fileName = "";
        this.csvHeaders = [];
        this.csvRows = [];
        this.previewRows = [];
        this.fieldMapping = {};
        this.batchName = "";
        this.batchDescription = "";
        this.isDryRun = false;
        this.importResult = {};
        this.batchId = null;
        this.jobId = null;
        this.processingStatus = {};
        this.isPolling = false;
    }

    disconnectedCallback() {
        this.isPolling = false;
    }

    // ---- Helpers ----

    _stepClass(step) {
        const order = [STEP_UPLOAD, STEP_MAP, STEP_REVIEW, STEP_PROCESSING];
        const currentIdx = order.indexOf(this.currentStep);
        const stepIdx = order.indexOf(step);
        if (stepIdx < currentIdx) return "step completed";
        if (stepIdx === currentIdx) return "step active";
        return "step";
    }
}
