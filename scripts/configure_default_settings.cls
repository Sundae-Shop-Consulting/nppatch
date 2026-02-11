/**
* @description Configure all default Custom Settings. The default values used in this code have been copied
* from UTIL_CustomSettingsFacade to allow this logic to be executed against both managed and unmanaged orgs.
* @author Michael Smith
* @date 2020-09-17
*/


/**
 * @description Constants copied from NPPatch classes - CAO_Constants, HH_Household, RD2_Constants, UTIL_CustomSettingsFacade
 */
public static final String HH_ACCOUNT_PROCESSOR = 'Household Account';
public static final String HH_ACCOUNT_RT_DEVELOPER_NAME = 'HH_Account';
public static final String HH_MEMBER_CONTACT_ROLE = 'Household Member';
public static final String OCR_DONOR_ROLE = 'Donor';
public static final String NO_HOUSEHOLDS_PROCESSOR = 'No Contacts';
public static final String ALL_PROCESSOR = 'All New or Edited Contacts';
public static final String DEFAULT_OPPORTUNITY_CONTACT_ROLE_DONOR = OCR_DONOR_ROLE;
public static final String DEFAULT_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT = 'Soft Credit';
public static final Integer DEFAULT_ROLLUP_SKEW_MODE_BATCH_SIZE = 1000;
public static final Integer DEFAULT_ROLLUP_BATCH_SIZE = 200;
public static final Integer DEFAULT_ROLLUP_SKEW_DISPATCHER_SIZE = 300;
public static final Integer DEFAULT_ROLLUP_ATTACHED_OPP_SKEW_LIMIT  = 250;
public static final String ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS = 'All Sys Admins';

/**
 * @description Primary method called by the CCI Task to configure the Default Settings
 */
public static void initializeDefaultSettings() {
    // When calling this code in a managed context, the string %%%NAMESPACE%%% will be replaced with
    // "NAMESPACE__" via the cumulusci task in cumulusci.tasks.apex.anon.AnonymousApexTask.
    // Similarly %%%NAMESPACED_RT%%% will be replaced by "NAMESPACE." for namespaced record type support

    setAffiliationSettings();
    setAllocationSettings();
    setCustomizableRollupSettings();
    setHouseholdSettings();
    setContactAndOrgSettings();
    setRecurringDonationSettings();
    setErrorSettings();
}

// ==============================================================================================================
// SETTINGS METHODS
// ==============================================================================================================

/**
 * @description Configure the default Affiliations settings mimicking what is in UTIL_CustomSettingsFacade
 */
private static void setAffiliationSettings() {
    %%%NAMESPACE%%%Affiliations_Settings__c settings = %%%NAMESPACE%%%Affiliations_Settings__c.getOrgDefaults();

    if (settings.Id == null) {
        settings.%%%NAMESPACE%%%Automatic_Affiliation_Creation_Turned_On__c = true;
        upsert settings;
    }
}

/**
 * @description Configure the default Allocation settings mimicking what is in UTIL_CustomSettingsFacade
 */
private static void setAllocationSettings() {
    %%%NAMESPACE%%%Allocations_Settings__c settings = %%%NAMESPACE%%%Allocations_Settings__c.getOrgDefaults();

    if (settings.Id == null) {
        settings.%%%NAMESPACE%%%Default_Allocations_Enabled__c = false;
        settings.%%%NAMESPACE%%%Default__c = null;
        settings.%%%NAMESPACE%%%Excluded_Opp_RecTypes__c = null;
        settings.%%%NAMESPACE%%%Excluded_Opp_Types__c = null;
        settings.%%%NAMESPACE%%%Payment_Allocations_Enabled__c = false;
        settings.%%%NAMESPACE%%%Rollup_N_Day_Value__c = 365;
        settings.%%%NAMESPACE%%%Use_Fiscal_Year_for_Rollups__c = false;
        upsert settings;
    }
}

/**
 * @description Configure the default Customizable Rollup settings mimicking what is in UTIL_CustomSettingsFacade
 */
private static void setCustomizableRollupSettings() {
    %%%NAMESPACE%%%Customizable_Rollup_Settings__c settings = %%%NAMESPACE%%%Customizable_Rollup_Settings__c.getOrgDefaults();

    if (settings.Id == null) {
        // These are copied from UTIL_CustomSettingsFacade.configRollupSettings();
        settings.%%%NAMESPACE%%%Customizable_Rollups_Enabled__c = false;
        settings.%%%NAMESPACE%%%Rollups_Account_Batch_Size__c = DEFAULT_ROLLUP_BATCH_SIZE;
        settings.%%%NAMESPACE%%%Rollups_Contact_Batch_Size__c = DEFAULT_ROLLUP_BATCH_SIZE;
        settings.%%%NAMESPACE%%%Rollups_Account_SkewMode_Batch_Size__c = DEFAULT_ROLLUP_SKEW_MODE_BATCH_SIZE;
        settings.%%%NAMESPACE%%%Rollups_Contact_SkewMode_Batch_Size__c = DEFAULT_ROLLUP_SKEW_MODE_BATCH_SIZE;
        settings.%%%NAMESPACE%%%Rollups_Account_Soft_Credit_Batch_Size__c = DEFAULT_ROLLUP_BATCH_SIZE;
        settings.%%%NAMESPACE%%%Rollups_Contact_Soft_Credit_Batch_Size__c = DEFAULT_ROLLUP_BATCH_SIZE;
        settings.%%%NAMESPACE%%%Rollups_AcctContactSoftCredit_Batch_Size__c = DEFAULT_ROLLUP_BATCH_SIZE;
        settings.%%%NAMESPACE%%%Rollups_GAU_Batch_Size__c = DEFAULT_ROLLUP_SKEW_MODE_BATCH_SIZE;
        settings.%%%NAMESPACE%%%Rollups_Skew_Dispatcher_Batch_Size__c = DEFAULT_ROLLUP_SKEW_DISPATCHER_SIZE;
        settings.%%%NAMESPACE%%%Rollups_Limit_on_Attached_Opps_for_Skew__c = DEFAULT_ROLLUP_ATTACHED_OPP_SKEW_LIMIT;
        settings.%%%NAMESPACE%%%Disable_Related_Records_Filter__c = false;
        settings.%%%NAMESPACE%%%AccountHardCreditNonSkew_Incremental__c = true;
        settings.%%%NAMESPACE%%%ContactHardCreditNonSkew_Incremental__c = true;
        upsert settings;
    }
}

/**
 * @description Configure the default Household settings mimicking what is in UTIL_CustomSettingsFacade
 */
private static void setHouseholdSettings() {

    %%%NAMESPACE%%%Households_Settings__c settings = %%%NAMESPACE%%%Households_Settings__c.getOrgDefaults();
    if (settings.Id == null) {
        // These are copied from UTIL_CustomSettingsFacade.configHouseholdSettings();
        settings.%%%NAMESPACE%%%Household_Rules__c = ALL_PROCESSOR;
        settings.%%%NAMESPACE%%%Household_Member_Contact_Role__c = HH_MEMBER_CONTACT_ROLE;
        settings.%%%NAMESPACE%%%Always_Rollup_to_Primary_Contact__c = false;
        settings.%%%NAMESPACE%%%Enable_Opp_Rollup_Triggers__c = true;
        settings.%%%NAMESPACE%%%Excluded_Account_Opp_Rectypes__c = null;
        settings.%%%NAMESPACE%%%Excluded_Account_Opp_Types__c = null;
        settings.%%%NAMESPACE%%%Excluded_Contact_Opp_Rectypes__c = null;
        settings.%%%NAMESPACE%%%Excluded_Contact_Opp_Types__c = null;
        settings.%%%NAMESPACE%%%Rollup_N_Day_Value__c = 365;
        settings.%%%NAMESPACE%%%Membership_Grace_Period__c = 30;
        settings.%%%NAMESPACE%%%Advanced_Household_Naming__c = true;
        settings.%%%NAMESPACE%%%Async_Household_Naming__c = false;
        settings.%%%NAMESPACE%%%Schedule_Job_Limit__c = 25;
        settings.%%%NAMESPACE%%%Household_OCR_Excluded_Recordtypes__c = null;
        settings.%%%NAMESPACE%%%Household_Creation_Excluded_Recordtypes__c = null;
        settings.%%%NAMESPACE%%%Enable_Soft_Credit_Rollups__c = true;
        settings.%%%NAMESPACE%%%Soft_Credit_Roles__c = 'Matched Donor;Soft Credit;Household Member';
        settings.%%%NAMESPACE%%%Matched_Donor_Role__c = 'Matched Donor';
        settings.%%%NAMESPACE%%%Household_Contact_Roles_On__c = true;
        settings.%%%NAMESPACE%%%Seasonal_Addresses_Batch_Size__c = 10;
        settings.%%%NAMESPACE%%%Household_Rules__c = NO_HOUSEHOLDS_PROCESSOR;
    }

    settings.%%%NAMESPACE%%%Membership_Record_Types__c = getOppRecordType('Membership');
    upsert settings;
}

/**
 * @description Configure the default Contacts & Org settings mimicking what is in UTIL_CustomSettingsFacade
 */
private void setContactAndOrgSettings() {
    %%%NAMESPACE%%%Contacts_And_Orgs_Settings__c settings = %%%NAMESPACE%%%Contacts_And_Orgs_Settings__c.getOrgDefaults();

    if (settings.Id == null) {
        // These are copied from UTIL_CustomSettingsFacade.configContactAndOrgSettings();
        settings.%%%NAMESPACE%%%Enable_Opportunity_Contact_Role_Trigger__c = false;
        settings.%%%NAMESPACE%%%Payments_Enabled__c  = true;
        settings.%%%NAMESPACE%%%Opportunity_Contact_Role_Default_role__c = DEFAULT_OPPORTUNITY_CONTACT_ROLE_DONOR;
        settings.%%%NAMESPACE%%%Contact_Role_for_Organizational_Opps__c = DEFAULT_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT;
        settings.%%%NAMESPACE%%%Account_Processor__c = HH_ACCOUNT_PROCESSOR;
        settings.%%%NAMESPACE%%%Opp_RecTypes_Excluded_for_Payments__c = null;
        settings.%%%NAMESPACE%%%Opp_Types_Excluded_for_Payments__c = null;
        Recordtypeinfo householdAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(HH_ACCOUNT_RT_DEVELOPER_NAME);
        if (householdAccount != null) {
            settings.%%%NAMESPACE%%%HH_Account_RecordTypeID__c = householdAccount.getRecordTypeId();
        }

    }

    settings.%%%NAMESPACE%%%Honoree_Opportunity_Contact_Role__c = 'Honoree Contact';
    settings.%%%NAMESPACE%%%Notification_Recipient_Opp_Contact_Role__c = 'Notification Contact';
    settings.%%%NAMESPACE%%%Payments_Auto_Close_Stage_Name__c = getClosedWonStage();
    upsert settings;
}

/**
 * @description Configure the default Recurring Donation settings mimicking what is in UTIL_CustomSettingsFacade
 */
private void setRecurringDonationSettings() {
    %%%NAMESPACE%%%Recurring_Donations_Settings__c settings = %%%NAMESPACE%%%Recurring_Donations_Settings__c.getOrgDefaults();
    if (settings.Id == null) {
        // These are copied from UTIL_CustomSettingsFacade.configRecurringDonationSettings();
        settings.%%%NAMESPACE%%%Add_Campaign_to_All_Opportunites__c = true;
        settings.%%%NAMESPACE%%%Maximum_Donations__c = 50;
        settings.%%%NAMESPACE%%%Recurring_Donation_Batch_Size__c = 50;
        settings.%%%NAMESPACE%%%DataMigrationBatchSize__c = 25;
        settings.%%%NAMESPACE%%%Opportunity_Forecast_Months__c = 12;
        settings.%%%NAMESPACE%%%Open_Opportunity_Behavior__c = 'Mark_Opportunities_Closed_Lost';
        settings.%%%NAMESPACE%%%InstallmentOppAutoCreateOption__c = 'Always_Create_Next_Installment';
        settings.%%%NAMESPACE%%%InstallmentOppFirstCreateMode__c = 'Synchronous';
        settings.%%%NAMESPACE%%%DisableRollupsWhenCreatingInstallments__c = false;
        settings.%%%NAMESPACE%%%NextDonationDateMatchRangeDays__c = 3;

        settings.%%%NAMESPACE%%%EnableAutomaticNaming__c = false;
        settings.%%%NAMESPACE%%%IsRecurringDonations2Enabled__c = false;
        settings.%%%NAMESPACE%%%UseFiscalYearForRecurringDonationValue__c = false;

    }

    settings.%%%NAMESPACE%%%Record_Type__c = getOppRecordType('Donation');
    settings.%%%NAMESPACE%%%EnableAutomaticNaming__c = true;
    upsert settings;
}

/**
 * @description Configure the default Error settings mimicking what is in UTIL_CustomSettingsFacade
 */
private void setErrorSettings() {

    %%%NAMESPACE%%%Error_Settings__c settings = %%%NAMESPACE%%%Error_Settings__c.getOrgDefaults();

    if (settings.Id == null) {
        // These are copied from UTIL_CustomSettingsFacade.configErrorSettings();
        settings.%%%NAMESPACE%%%Store_Errors_On__c = true;
        settings.%%%NAMESPACE%%%Error_Notifications_On__c = true;
        settings.%%%NAMESPACE%%%Error_Notifications_To__c = ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS;
        settings.%%%NAMESPACE%%%Disable_Error_Handling__c = false;
        settings.%%%NAMESPACE%%%OverrideFeature_PilotEnabled__c = false;
        settings.%%%NAMESPACE%%%Enable_Debug__c = false;
        settings.%%%NAMESPACE%%%Respect_Duplicate_Rule_Settings__c = false;
        upsert settings;
    }
}

// ==============================================================================================================
// HELPER METHODS
// ==============================================================================================================

/**
 * @description Retrieve the active ClosedWon stage name
 */
private static String getClosedWonStage() {
    OpportunityStage closedWonStage = [SELECT MasterLabel FROM OpportunityStage
        WHERE IsActive = true AND IsWon = true LIMIT 1];
    return closedWonStage.MasterLabel;
}

/**
 * @description Retrieve the specified record type, or the first active RT if that fails
 */
private static String getOppRecordType(String rtDevName) {
    Recordtypeinfo oppRt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(rtDevName);
    if (oppRt == null) {
        oppRt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NPPatch_Default');
    }
    return oppRt.getRecordTypeId();
}
