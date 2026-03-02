import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import runInitialization from "@salesforce/apex/NppatchSettingsController.runInitialization";

export default class StgPanelHealthCheck extends LightningElement {
    _isRunning = false;
    _runningMessage = "";
    _hasResults = false;
    _results = [];
    _passCount = 0;
    _failCount = 0;
    _warnCount = 0;

    async handleRunHealthCheck() {
        this._isRunning = true;
        this._runningMessage = "Running health check...";
        this._hasResults = false;
        try {
            // TODO: Wire up actual health check Apex method
            await new Promise((resolve) => setTimeout(resolve, 1500));
            this._results = [
                {
                    id: "placeholder",
                    status: "info",
                    setting: "Health Check",
                    description:
                        "The Health Check API is being migrated. For now, please run health checks from the classic NPPatch Settings page.",
                    solution: null,
                    iconName: "utility:info",
                    rowClass: "result-row result-info",
                },
            ];
            this._passCount = 0;
            this._failCount = 0;
            this._warnCount = 0;
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

    async handleReinitialize() {
        this._isRunning = true;
        this._runningMessage = "Reinitializing TDTM defaults and scheduled jobs...";
        try {
            await runInitialization();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "TDTM defaults and scheduled jobs have been reinitialized.",
                    variant: "success",
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: error?.body?.message || "An error occurred during reinitialization.",
                    variant: "error",
                })
            );
        } finally {
            this._isRunning = false;
        }
    }
}
