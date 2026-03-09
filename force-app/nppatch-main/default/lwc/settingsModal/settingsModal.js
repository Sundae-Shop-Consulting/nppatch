import { api } from "lwc";
import LightningModal from "lightning/modal";

// Panels migrated to the new pattern (no internal footer, expose @api save/reset)
const PANEL_SELECTORS = {
    accountModel: "c-stg-panel-account-model",
    affiliations: "c-stg-panel-affiliations",
    allocations: "c-stg-panel-allocations",
    campaignMembers: "c-stg-panel-campaign-members",
    contactRoles: "c-stg-panel-contact-roles",
    donorStatistics: "c-stg-panel-donor-statistics",
    duplicateRules: "c-stg-panel-duplicate-rules",
    errorNotif: "c-stg-panel-error-notif",
    households: "c-stg-panel-households",
    leads: "c-stg-panel-leads",
    membership: "c-stg-panel-membership",
    payments: "c-stg-panel-payments",
    relationships: "c-stg-panel-relationships",
    schedule: "c-stg-panel-schedule",
    addressVerification: "c-stg-panel-addr-verification",
};

export default class SettingsModal extends LightningModal {
    @api panelName;
    @api panelTitle;
    _isSaving = false;

    get showModalFooter() {
        return this.panelName in PANEL_SELECTORS;
    }

    get isAccountModelPanel() { return this.panelName === "accountModel"; }
    get isLeadsPanel() { return this.panelName === "leads"; }
    get isAffiliationsPanel() { return this.panelName === "affiliations"; }
    get isMembershipPanel() { return this.panelName === "membership"; }
    get isPaymentsPanel() { return this.panelName === "payments"; }
    get isDonorStatisticsPanel() { return this.panelName === "donorStatistics"; }
    get isCampaignMembersPanel() { return this.panelName === "campaignMembers"; }
    get isContactRolesPanel() { return this.panelName === "contactRoles"; }
    get isAllocationsPanel() { return this.panelName === "allocations"; }
    get isDuplicateRulesPanel() { return this.panelName === "duplicateRules"; }
    get isErrorNotifPanel() { return this.panelName === "errorNotif"; }
    get isRelationshipsPanel() { return this.panelName === "relationships"; }
    get isHouseholdsPanel() { return this.panelName === "households"; }
    get isSchedulePanel() { return this.panelName === "schedule"; }
    get isRelReciprocalPanel() { return this.panelName === "relReciprocal"; }
    get isRelAutoCreatePanel() { return this.panelName === "relAutoCreate"; }
    get isOppNamingPanel() { return this.panelName === "oppNaming"; }
    get isPaymentMappingPanel() { return this.panelName === "paymentMapping"; }
    get isTdtmPanel() { return this.panelName === "tdtm"; }
    get isAddressVerificationPanel() { return this.panelName === "addressVerification"; }
    get isCustomizableRollupsPanel() { return this.panelName === "customizableRollups"; }
    get isRd2StatusMappingPanel() { return this.panelName === "rd2StatusMapping"; }
    get isRd2StatusAutomationPanel() { return this.panelName === "rd2StatusAutomation"; }
    get isAdvancedMappingPanel() { return this.panelName === "advancedMapping"; }

    async handleSave() {
        const selector = PANEL_SELECTORS[this.panelName];
        if (!selector) {
            return;
        }
        const panel = this.template.querySelector(selector);
        if (!panel) {
            return;
        }
        this._isSaving = true;
        try {
            const success = await panel.save();
            if (success) {
                this.close("saved");
            }
        } finally {
            this._isSaving = false;
        }
    }

    handleCancel() {
        this.close();
    }
}
