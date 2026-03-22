import { LightningElement, wire } from "lwc";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";
import ensureSettingsExist from "@salesforce/apex/NppatchSettingsController.ensureSettingsExist";
import SettingsModal from "c/settingsModal";

import stgNPPatchSettingsTitle from "@salesforce/label/c.stgNPPatchSettingsTitle";
import insufficientPermissions from "@salesforce/label/c.commonInsufficientPermissions";
import accessDeniedMessage from "@salesforce/label/c.addrCopyConAddBtnFls";

const PANEL_SETTINGS = {
    accountModel: ["Contacts_And_Orgs_Settings__c"],
    addressVerification: ["Addr_Verification_Settings__c"],
    affiliations: ["Affiliations_Settings__c"],
    allocations: ["Allocations_Settings__c"],
    campaignMembers: ["Contacts_And_Orgs_Settings__c"],
    contactRoles: ["Contacts_And_Orgs_Settings__c", "Households_Settings__c"],
    donorStatistics: ["Households_Settings__c"],
    duplicateRules: ["Error_Settings__c"],
    errorNotif: ["Error_Settings__c"],
    households: ["Household_Naming_Settings__c", "Households_Settings__c"],
    leads: ["Contacts_And_Orgs_Settings__c"],
    membership: ["Households_Settings__c"],
    payments: ["Contacts_And_Orgs_Settings__c"],
    relationships: ["Relationship_Settings__c"],
    schedule: [
        "Customizable_Rollup_Settings__c",
        "Recurring_Donations_Settings__c",
        "Levels_Settings__c",
        "Households_Settings__c",
        "Error_Settings__c",
    ],
};

const SETTINGS_GROUPS = [
    {
        label: "People",
        tiles: [
            {
                name: "accountModel",
                title: "Account Model Settings",
                description:
                    "Configure how Contacts relate to Accounts — Household, One-to-One, or Individual bucket model.",
            },
            {
                name: "households",
                title: "Household Settings",
                description: "Control naming formats, greetings, and rules for Household Accounts.",
            },
            {
                name: "addressVerification",
                title: "Address Verification Settings",
                description: "Validate and standardize mailing addresses using an external verification service.",
            },
            {
                name: "leads",
                title: "Lead Settings",
                description: "Control whether Opportunities are created during Lead conversion.",
            },
        ],
    },
    {
        label: "Relationships",
        tiles: [
            {
                name: "affiliations",
                title: "Affiliation Settings",
                description: "Automatically track organizational connections when a Contact's Account changes.",
            },
            {
                name: "relationships",
                title: "Relationship Settings",
                description: "Configure how reciprocal relationships are created between Contacts.",
            },
            {
                name: "relReciprocal",
                title: "Reciprocal Relationships",
                size: "large",
                description: "Define how each relationship type maps to its reciprocal based on gender.",
            },
            {
                name: "relAutoCreate",
                title: "Auto-Create Relationships",
                description: "Automatically create Relationships when specific lookup fields are populated.",
            },
        ],
    },
    {
        label: "Donations",
        tiles: [
            {
                name: "oppNaming",
                title: "Opportunity Naming",
                size: "large",
                description: "Define rules for automatically generating Opportunity Name fields using merge fields.",
            },
            {
                name: "membership",
                title: "Membership Settings",
                description: "Configure membership record types and the grace period for reporting.",
            },
            {
                name: "payments",
                title: "Payment Settings",
                description: "Control automatic Payment creation and which record types to exclude.",
            },
            {
                name: "paymentMapping",
                title: "Payment Mappings",
                description: "Map Opportunity fields to Payment fields during automatic Payment creation.",
            },
            {
                name: "allocations",
                title: "Allocation Settings",
                description: "Configure default GAU Allocations and fund tracking behavior.",
            },
            {
                name: "donorStatistics",
                title: "Donor Statistics Settings",
                description: "Configure the rolling window and rules for donor giving summary calculations.",
            },
            {
                name: "contactRoles",
                title: "Contact Role Settings",
                description: "Control automatic Contact Role assignment during donation processing.",
            },
            {
                name: "campaignMembers",
                title: "Campaign Member Settings",
                description: "Automate Campaign Member status updates when Opportunities are linked to Campaigns.",
            },
            {
                name: "customizableRollups",
                title: "Customizable Rollups",
                description: "Configure rollup definitions for summary totals on Accounts, Contacts, and GAUs.",
            },
        ],
    },
    {
        label: "Recurring Donations",
        tiles: [
            {
                name: "rd2StatusMapping",
                title: "Status Mapping",
                description: "Map Recurring Donation statuses to Opportunity stages and outcomes.",
            },
            {
                name: "rd2StatusAutomation",
                title: "Status Automation",
                description:
                    "Configure rules for automatically changing Recurring Donation status based on payment history.",
            },
        ],
    },
    {
        label: "System",
        tiles: [
            {
                name: "schedule",
                title: "Batch Process Settings",
                description: "Configure batch sizes for scheduled Apex jobs that calculate rollups and process data.",
            },
            {
                name: "errorNotif",
                title: "Error Notification Settings",
                description: "Configure error logging and notification recipients for processing errors.",
            },
            {
                name: "duplicateRules",
                title: "Duplicate Rule Settings",
                description:
                    "Control whether NPPatch respects Salesforce Duplicate Rules when creating or updating records.",
            },
            {
                name: "tdtm",
                title: "Trigger Configuration",
                description: "Manage which Apex trigger handlers execute and in what order.",
            },
            {
                name: "advancedMapping",
                title: "Advanced Mapping",
                description: "Customize field mappings for Data Import batch processing.",
            },
        ],
    },
];

export default class NppatchSettings extends LightningElement {
    _isLoading = true;
    _isAccessDenied = false;
    _settingsReady = false;
    _adminChecked = false;
    _ensuredSettings = new Set();

    labels = {
        title: stgNPPatchSettingsTitle,
        insufficientPermissions,
        accessDeniedMessage,
    };

    settingsGroups = SETTINGS_GROUPS;

    connectedCallback() {
        this._ensureAllSettings();
    }

    @wire(isAdmin)
    wiredIsAdmin({ data, error }) {
        if (data !== undefined) {
            this._adminChecked = true;
            if (!data) {
                this._isAccessDenied = true;
            }
            this._checkReady();
        } else if (error) {
            this._adminChecked = true;
            this._isAccessDenied = true;
            this._checkReady();
        }
    }

    _checkReady() {
        if (this._settingsReady && this._adminChecked) {
            this._isLoading = false;
        }
    }

    async _ensureAllSettings() {
        const allSettings = new Set(Object.values(PANEL_SETTINGS).flat());
        const needed = [...allSettings].filter((s) => !this._ensuredSettings.has(s));
        if (needed.length > 0) {
            try {
                await ensureSettingsExist({ settingsObjectNames: needed });
                needed.forEach((s) => this._ensuredSettings.add(s));
            } catch (_e) {
                // Settings may already exist; proceed anyway
            }
        }
        this._settingsReady = true;
        this._checkReady();
    }

    async handleOpenPanel(event) {
        const name = event.currentTarget.dataset.name;
        let tile;
        for (const group of SETTINGS_GROUPS) {
            tile = group.tiles.find((t) => t.name === name);
            if (tile) {
                break;
            }
        }
        await SettingsModal.open({
            size: tile?.size || "medium",
            panelName: name,
            panelTitle: tile?.title || "",
        });
    }

    get isReady() {
        return !this._isLoading && !this._isAccessDenied;
    }
}
