import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import runBatch from "@salesforce/apex/BulkProcessController.runBatch";
import getSettings from "@salesforce/apex/NppatchSettingsController.getSettings";

const PROCESSES = [
    {
        name: "rollupBatch",
        title: "Rollup Batch",
        description:
            "Runs all Customizable Rollup batch jobs to recalculate donor statistics on Accounts and Contacts. This processes hard credit, soft credit, and recurring donation rollups.",
        buttonLabel: "Run Rollup Batch",
        iconName: "utility:refresh",
    },
    {
        name: "alloBatch",
        title: "Allocation Rollup Batch",
        description:
            "Recalculates rollup totals for General Accounting Units (GAUs). Run this after creating or modifying Allocations to ensure GAU summary fields are current.",
        buttonLabel: "Run Allocation Rollup",
        iconName: "utility:refresh",
    },
    {
        name: "makeDefaultAllocations",
        title: "Create Default Allocations",
        description:
            "Creates default GAU Allocation records for existing Opportunities that don't already have one. Useful after enabling Default Allocations to backfill historical data.",
        buttonLabel: "Create Default Allocations",
        iconName: "utility:add",
    },
    {
        name: "createPayments",
        title: "Create Missing Payments",
        description:
            "Creates Payment records for existing Opportunities that should have them but don't. Useful after enabling Automatic Payments to backfill historical Opportunities.",
        buttonLabel: "Create Missing Payments",
        iconName: "utility:add",
    },
    {
        name: "refreshHouseholdData",
        title: "Refresh Household Data",
        description:
            "Recalculates all Household Account names, formal greetings, and informal greetings based on current naming format settings.",
        buttonLabel: "Refresh Household Names",
        iconName: "utility:refresh",
    },
    {
        name: "oppNamingBatch",
        title: "Opportunity Naming Refresh",
        description:
            "Regenerates the Name field on all Opportunities based on the current Opportunity Naming settings.",
        buttonLabel: "Refresh Opportunity Names",
        iconName: "utility:refresh",
    },
    {
        name: "updatePrimaryContact",
        title: "Update Primary Contact",
        description: "Updates the Primary Contact lookup field on all Opportunities based on their Contact Roles.",
        buttonLabel: "Update Primary Contacts",
        iconName: "utility:user",
    },
    {
        name: "lvlAssignBatch",
        title: "Level Assignment Batch",
        description:
            "Evaluates all Level definitions and assigns the appropriate Level to each Account, Contact, or other target object.",
        buttonLabel: "Run Level Assignment",
        iconName: "utility:assignment",
    },
    {
        name: "primaryContactRoleMerge",
        title: "Primary Contact Role Merge",
        description:
            "Identifies Opportunities with duplicate Primary Contact Roles and removes the extras, keeping only one Primary OCR per Opportunity.",
        buttonLabel: "Remove Duplicate Primary OCRs",
        iconName: "utility:merge",
    },
    {
        name: "resetTriggerHandlers",
        title: "Reset Trigger Handlers",
        description:
            "Resets trigger dispatch (TDTM) handler records to their defaults. Use this after deployment or when trigger handlers appear to be missing or misconfigured.",
        buttonLabel: "Reset Trigger Handlers",
        iconName: "utility:settings",
    },
    {
        name: "rescheduleJobs",
        title: "Reschedule Default Jobs",
        description:
            "Aborts deprecated scheduled jobs and re-schedules all standard NPPatch scheduled jobs. Use this when scheduled jobs are missing or were aborted due to user deactivation.",
        buttonLabel: "Reschedule Jobs",
        iconName: "utility:clock",
    },
];

const RESCHEDULE_DISABLED_DESC =
    "Automatic scheduling is disabled. To enable, uncheck \u201cDon\u2019t Enable Auto Schedule Default NPPatch Jobs\u201d in NPPatch Settings > System > Error Settings.";

export default class BulkProcesses extends LightningElement {
    _runningProcess = null;
    _autoScheduleDisabled = false;

    @wire(getSettings, { objectName: "Error_Settings__c" })
    wiredErrorSettings({ data }) {
        if (data) {
            this._autoScheduleDisabled = !!data.Don_t_Auto_Schedule_Default_NPPatch_Jobs__c;
        }
    }

    get processes() {
        return PROCESSES.map((p) => {
            const isReschedule = p.name === "rescheduleJobs";
            return {
                ...p,
                description: isReschedule && this._autoScheduleDisabled ? RESCHEDULE_DISABLED_DESC : p.description,
                isRunning: this._runningProcess === p.name,
                isDisabled: this._runningProcess !== null || (isReschedule && this._autoScheduleDisabled),
            };
        });
    }

    async handleRun(event) {
        const batchName = event.currentTarget.dataset.name;
        this._runningProcess = batchName;
        try {
            await runBatch({ batchName });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Job submitted. Check the Apex Jobs page for progress.",
                    variant: "success",
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: error?.body?.message || "An error occurred.",
                    variant: "error",
                })
            );
        } finally {
            this._runningProcess = null;
        }
    }
}
