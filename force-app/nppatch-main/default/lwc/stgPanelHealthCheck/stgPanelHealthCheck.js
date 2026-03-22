import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import runHealthCheck from "@salesforce/apex/HealthCheckController.runHealthCheck";

const STATUS_ICON = {
    Success: "utility:success",
    Warning: "utility:warning",
    Error: "utility:error",
};

const STATUS_VARIANT = {
    Success: "success",
    Warning: "warning",
    Error: "error",
};

const STATUS_CLASS = {
    Success: "result-row result-pass",
    Warning: "result-row result-warn",
    Error: "result-row result-fail",
};

const TAB_ALL = "all";
const TAB_ERRORS = "errors";
const TAB_WARNINGS = "warnings";
const TAB_PASS = "pass";

export default class StgPanelHealthCheck extends LightningElement {
    _isRunning = false;
    _runningMessage = "";
    _hasResults = false;
    @track _results = [];
    _passCount = 0;
    _failCount = 0;
    _warnCount = 0;
    _elapsedTime = "";
    _activeTab = TAB_ALL;

    connectedCallback() {
        this._runCheck();
    }

    handleRefresh() {
        this._runCheck();
    }

    get filteredResults() {
        if (this._activeTab === TAB_ALL) {
            return this._results;
        }
        if (this._activeTab === TAB_ERRORS) {
            return this._results.filter((r) => r.status === "Error");
        }
        if (this._activeTab === TAB_WARNINGS) {
            return this._results.filter((r) => r.status === "Warning");
        }
        if (this._activeTab === TAB_PASS) {
            return this._results.filter((r) => r.status === "Success");
        }
        return this._results;
    }

    get tabAllClass() {
        return this._tabClass(TAB_ALL);
    }
    get tabErrorsClass() {
        return this._tabClass(TAB_ERRORS);
    }
    get tabWarningsClass() {
        return this._tabClass(TAB_WARNINGS);
    }
    get tabPassClass() {
        return this._tabClass(TAB_PASS);
    }

    handleTabAll() {
        this._activeTab = TAB_ALL;
    }
    handleTabErrors() {
        this._activeTab = TAB_ERRORS;
    }
    handleTabWarnings() {
        this._activeTab = TAB_WARNINGS;
    }
    handleTabPass() {
        this._activeTab = TAB_PASS;
    }

    async _runCheck() {
        this._isRunning = true;
        this._runningMessage = "Running health check...";
        this._hasResults = false;
        this._activeTab = TAB_ALL;
        try {
            const start = Date.now();
            const rawResults = await runHealthCheck();
            const elapsed = ((Date.now() - start) / 1000).toFixed(1);
            this._elapsedTime = `${elapsed}s`;

            let passCount = 0;
            let failCount = 0;
            let warnCount = 0;

            this._results = rawResults.map((r, idx) => {
                if (r.status === "Success") {
                    passCount++;
                } else if (r.status === "Error") {
                    failCount++;
                } else if (r.status === "Warning") {
                    warnCount++;
                }
                return {
                    id: `hc-${idx}`,
                    setting: r.name || "Check",
                    status: r.status,
                    description: r.details,
                    solution: r.solution,
                    iconName: STATUS_ICON[r.status] || "utility:info",
                    iconVariant: STATUS_VARIANT[r.status] || "",
                    rowClass: STATUS_CLASS[r.status] || "result-row result-info",
                };
            });

            this._passCount = passCount;
            this._failCount = failCount;
            this._warnCount = warnCount;
            this._hasResults = true;
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: error?.body?.message || "An error occurred running the health check.",
                    variant: "error",
                })
            );
        } finally {
            this._isRunning = false;
        }
    }

    _tabClass(tab) {
        return "tab" + (this._activeTab === tab ? " tab-active" : "");
    }
}
