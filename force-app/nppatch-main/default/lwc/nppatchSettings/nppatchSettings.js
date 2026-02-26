import { LightningElement, wire } from "lwc";
import isAdmin from "@salesforce/apex/NppatchSettingsController.isAdmin";

import stgNPPatchSettingsTitle from "@salesforce/label/c.stgNPPatchSettingsTitle";
import insufficientPermissions from "@salesforce/label/c.commonInsufficientPermissions";
import accessDeniedMessage from "@salesforce/label/c.addrCopyConAddBtnFls";

// TODO Phase 2: Replace hardcoded nav labels with @salesforce/label imports
const NAV_GROUPS = [
    {
        label: "People",
        items: [
            { label: "Account Model", name: "accountModel" },
            { label: "Households", name: "households" },
            { label: "Address Verification", name: "addressVerification" },
            { label: "Leads", name: "leads" },
        ],
    },
    {
        label: "Relationships",
        items: [
            { label: "Affiliations", name: "affiliations" },
            { label: "Relationships", name: "relationships" },
            { label: "Reciprocal", name: "relReciprocal" },
            { label: "Auto-Create", name: "relAutoCreate" },
        ],
    },
    {
        label: "Donations",
        items: [
            { label: "Opportunity Naming", name: "oppNaming" },
            { label: "Membership", name: "membership" },
            { label: "Payments", name: "payments" },
            { label: "Payment Mappings", name: "paymentMapping" },
            { label: "Allocations", name: "allocations" },
            { label: "Donor Statistics", name: "donorStatistics" },
            { label: "Contact Roles", name: "contactRoles" },
            { label: "Campaign Members", name: "campaignMembers" },
            { label: "Customizable Rollups", name: "customizableRollups" },
        ],
    },
    {
        label: "Recurring Donations",
        items: [
            { label: "Status Mapping", name: "rd2StatusMapping" },
            { label: "Status Automation", name: "rd2StatusAutomation" },
        ],
    },
    {
        label: "Bulk Data Processes",
        items: [
            { label: "Batch Process Settings", name: "schedule" },
            { label: "Rollup Batch", name: "oppBatch" },
            { label: "Allocation Rollup Batch", name: "alloBatch" },
            { label: "Create Default Allocations", name: "makeDefaultAllocations" },
            { label: "Create Missing Payments", name: "createPayments" },
            { label: "Refresh Household Data", name: "refreshHouseholdData" },
            { label: "Opportunity Naming Refresh", name: "oppNamingBatch" },
            { label: "Update Primary Contact", name: "updatePrimaryContact" },
            { label: "Level Assignment Batch", name: "lvlAssignBatch" },
            { label: "Primary Contact Role Merge", name: "primaryContactRoleMerge" },
        ],
    },
    {
        label: "System Tools",
        items: [
            { label: "Health Check", name: "healthCheck" },
            { label: "Error Log", name: "errorLog" },
            { label: "Error Notifications", name: "errorNotif" },
            { label: "Trigger Configuration", name: "tdtm" },
            { label: "Advanced Mapping", name: "advancedMapping" },
        ],
    },
];

export default class NppatchSettings extends LightningElement {
    _isLoading = true;
    _isAccessDenied = false;
    _activePanel = "membership";

    labels = {
        title: stgNPPatchSettingsTitle,
        insufficientPermissions,
        accessDeniedMessage,
    };

    navGroups = NAV_GROUPS;

    @wire(isAdmin)
    wiredIsAdmin({ data, error }) {
        if (data !== undefined) {
            this._isLoading = false;
            if (!data) {
                this._isAccessDenied = true;
            }
        } else if (error) {
            this._isLoading = false;
            this._isAccessDenied = true;
        }
    }

    handleNavSelect(event) {
        this._activePanel = event.detail.name;
    }

    get isReady() {
        return !this._isLoading && !this._isAccessDenied;
    }

    get isAccountModelPanel() { return this._activePanel === "accountModel"; }
    get isLeadsPanel() { return this._activePanel === "leads"; }
    get isAffiliationsPanel() { return this._activePanel === "affiliations"; }
    get isMembershipPanel() { return this._activePanel === "membership"; }
    get isPaymentsPanel() { return this._activePanel === "payments"; }
    get isDonorStatisticsPanel() { return this._activePanel === "donorStatistics"; }
    get isCampaignMembersPanel() { return this._activePanel === "campaignMembers"; }
    get isContactRolesPanel() { return this._activePanel === "contactRoles"; }
    get isAllocationsPanel() { return this._activePanel === "allocations"; }
    get isErrorNotifPanel() { return this._activePanel === "errorNotif"; }
    get isRelationshipsPanel() { return this._activePanel === "relationships"; }
    get isHouseholdsPanel() { return this._activePanel === "households"; }
    get isSchedulePanel() { return this._activePanel === "schedule"; }
    get isOppBatchPanel() { return this._activePanel === "oppBatch"; }
    get isAlloBatchPanel() { return this._activePanel === "alloBatch"; }
    get isMakeDefaultAllocationsPanel() { return this._activePanel === "makeDefaultAllocations"; }
    get isCreatePaymentsPanel() { return this._activePanel === "createPayments"; }
    get isRefreshHouseholdDataPanel() { return this._activePanel === "refreshHouseholdData"; }
    get isOppNamingBatchPanel() { return this._activePanel === "oppNamingBatch"; }
    get isUpdatePrimaryContactPanel() { return this._activePanel === "updatePrimaryContact"; }
    get isLvlAssignBatchPanel() { return this._activePanel === "lvlAssignBatch"; }
    get isPrimaryContactRoleMergePanel() { return this._activePanel === "primaryContactRoleMerge"; }
    get isRelReciprocalPanel() { return this._activePanel === "relReciprocal"; }
    get isRelAutoCreatePanel() { return this._activePanel === "relAutoCreate"; }
    get isOppNamingPanel() { return this._activePanel === "oppNaming"; }
    get isPaymentMappingPanel() { return this._activePanel === "paymentMapping"; }
    get isTdtmPanel() { return this._activePanel === "tdtm"; }
    get isAddressVerificationPanel() { return this._activePanel === "addressVerification"; }
    get isCustomizableRollupsPanel() { return this._activePanel === "customizableRollups"; }
    get isRd2StatusMappingPanel() { return this._activePanel === "rd2StatusMapping"; }
    get isRd2StatusAutomationPanel() { return this._activePanel === "rd2StatusAutomation"; }
    get isHealthCheckPanel() { return this._activePanel === "healthCheck"; }
    get isErrorLogPanel() { return this._activePanel === "errorLog"; }
    get isAdvancedMappingPanel() { return this._activePanel === "advancedMapping"; }

    get showPlaceholder() {
        return false; // All panels are now implemented
    }
}
