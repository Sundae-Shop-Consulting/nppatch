/*
    Copyright (c) 2014, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2014
* @group Settings
* @description Test Class for the Install Script for the NPSP package.
*/
@isTest
public with sharing class STG_InstallScript_TEST {

    @TestSetup
    static void setupPermissions() {
        UTIL_TestPermissions.assignAdminPermissionSet();
    }

    private static final Integer ROLLUP_BATCH_SIZE = 333;

    /**
    * @description Returns true if tests should be skipped in 2GP namespaced context
    */
    private static Boolean shouldSkipIn2GP() {
        return String.isNotBlank(UTIL_Namespace.getNamespace());
    }

    /*******************************************************************************************************
    * @description A test exception class
    */
    private class STG_InstallException extends Exception {}

    /*********************************************************************************************************
    @description
        Test install on a new org populates the default settings and
        no exception is thrown if the custom settings don't exist
    verify:
        Settings match the expected defaults.
    **********************************************************************************************************/
    @isTest
    public static void newInstallCreatesDefaultSettings() {
        Test.testInstall(new STG_InstallScript(), null);
        verifyAllSettingsCreated();
    }

    /*********************************************************************************************************
    @description
        Test install on org with some partial settings will still populate the default settings and
        no exception is thrown if the custom settings don't exist
    verify:
        Settings match the expected defaults.
    **********************************************************************************************************/
    @isTest
    public static void newInstallPopulatesMissingSettings() {
        createSomeDefaultSettings();
        Test.testInstall(new STG_InstallScript(), null);
        verifyAllSettingsCreated();
    }

    /*********************************************************************************************************
    @description
        Test install on org with some deprecated settings will still populate the default settings and
        remove the deprecated setting
        no exception is thrown if the custom settings don't exist
    verify:
        Settings match the expected defaults.
    **********************************************************************************************************/
    @isTest
    public static void newInstallRemovesDeprecatedSettings() {
        createSomeDefaultSettings();

        insert new Trigger_Handler__c(Active__c = true, Asynchronous__c = false,
              Class__c = 'OPP_OpportunityNaming_TDTM', Load_Order__c = 0, Object__c = 'Opportunity',
              Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete');

        Test.testInstall(new STG_InstallScript(), null);
        verifyAllSettingsCreated();
    }

    /*********************************************************************************************************
    @description
        Test a push install will create the default settings and update any partial settings
        no exception is thrown if the custom settings don't exist
    verify:
        Settings match the expected defaults
    **********************************************************************************************************/
    @isTest
    public static void pushInstallCreatesDefaultSettingsAndPopulatesPartialSettings() {
        createSomeDefaultSettings();
        Customizable_Rollup_Settings__c expectedConfig = buildRollupSettingsWithPartialValues();
        Test.testInstall(new STG_InstallScript(), new Version(1,0), true);
        verifyAllSettingsCreated();
        assertRollupSettingsEqual(expectedConfig);
    }

    /*********************************************************************************************************
    @description
        Test a manual upgrade install will create the default settings and update any partial settings
        no exception is thrown if the custom settings don't exist
    verify:
        Settings match the expected defaults
    **********************************************************************************************************/
    @isTest
    public static void upgradeInstallCreatesDefaultSettingsAndPopulatesPartialSettings() {
        createSomeDefaultSettings();
        Customizable_Rollup_Settings__c expectedConfig = buildRollupSettingsWithPartialValues();
        Test.testInstall(new STG_InstallScript(), new Version(1,0), false);
        verifyAllSettingsCreated();
        assertRollupSettingsEqual(expectedConfig);
    }

    /*********************************************************************************************************
    @description
        Test new install with custom settings explicitly deleted will still create the default settings
        no exception is thrown if the custom settings don't exist
    verify:
        Settings match the expected defaults
    **********************************************************************************************************/
    @isTest
    public static void newInstallWithDeletedCustomSettingsCreatesDefaultSettings() {
        deleteAllCustomSettings();

        Test.testInstall(new STG_InstallScript(), null);

        Contacts_And_Orgs_Settings__c npe01Settings = UTIL_CustomSettingsFacade.getOrgContactsSettings();
        Households_Settings__c npo02Settings = UTIL_CustomSettingsFacade.getOrgHouseholdsSettings();
        Recurring_Donations_Settings__c npe03Settings = UTIL_CustomSettingsFacade.getOrgRecurringDonationsSettings();
        Relationship_Settings__c npe04Settings = UTIL_CustomSettingsFacade.getOrgRelationshipSettings();
        Affiliations_Settings__c npe05Settings = UTIL_CustomSettingsFacade.getOrgAffiliationsSettings();
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getOrgErrorSettings();
        Addr_Verification_Settings__c addrVerificationSetgs = UTIL_CustomSettingsFacade.getOrgAddressVerificationSettings();
        Household_Naming_Settings__c householdNamingSettings = UTIL_CustomSettingsFacade.getOrgHouseholdNamingSettings();
        Allocations_Settings__c allocationsSettings = UTIL_CustomSettingsFacade.getOrgAllocationsSettings();
        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getOrgDataImportSettings();
        Gift_Entry_Settings__c geSettings = UTIL_CustomSettingsFacade.getOrgGiftEntrySettings();
        Package_Settings__c pkgSettings = Package_Settings__c.getOrgDefaults();

        //If it's a new install we want to set the Household model by default
        System.assertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, npe01Settings.Account_Processor__c);
        System.assertEquals(false, npe01Settings.Enable_Opportunity_Contact_Role_Trigger__c);
        System.assertEquals(true, npe01Settings.Payments_Enabled__c);
        Recordtypeinfo householdAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(CAO_Constants.HH_ACCOUNT_RT_DEVELOPER_NAME);
        Id householdAccountId = (householdAccount == null ? null : householdAccount.getRecordTypeId());
        System.assertEquals(householdAccountId, npe01Settings.HH_Account_RecordTypeID__c);

        System.assertEquals(HH_Households.NO_HOUSEHOLDS_PROCESSOR, npo02Settings.Household_Rules__c);
        System.assertEquals(CAO_Constants.HH_MEMBER_CONTACT_ROLE, npo02Settings.Household_Member_Contact_Role__c);
        System.assertEquals(false, npo02Settings.Always_Rollup_to_Primary_Contact__c);
        System.assertEquals(true, npo02Settings.Enable_Opp_Rollup_Triggers__c);
        System.assertEquals(null, npo02Settings.Excluded_Account_Opp_Rectypes__c);
        System.assertEquals(null, npo02Settings.Excluded_Account_Opp_Types__c);
        System.assertEquals(null, npo02Settings.Excluded_Contact_Opp_Rectypes__c);
        System.assertEquals(null, npo02Settings.Excluded_Contact_Opp_Types__c);
        System.assertEquals(null, npo02Settings.Membership_Record_Types__c);
        System.assertEquals(365, npo02Settings.Rollup_N_Day_Value__c);
        System.assertEquals(30, npo02Settings.Membership_Grace_Period__c);
        System.assertEquals(true, npo02Settings.Advanced_Household_Naming__c);
        System.assertEquals(false, npo02Settings.Async_Household_Naming__c);
        System.assertEquals(UserInfo.getOrganizationId(), npo02Settings.Setupownerid);
        System.assertEquals(25, npo02Settings.Schedule_Job_Limit__c);
        System.assertEquals(null, npo02Settings.Household_OCR_Excluded_Recordtypes__c);
        System.assertEquals(null, npo02Settings.Household_Creation_Excluded_Recordtypes__c);
        System.assertEquals(HH_Households.NO_HOUSEHOLDS_PROCESSOR, npo02Settings.Household_Rules__c);
        System.assertEquals(true, npo02Settings.Enable_Soft_Credit_Rollups__c);
        System.assertEquals('Matched Donor;Soft Credit;Household Member', npo02Settings.Soft_Credit_Roles__c);
        System.assertEquals(true, npo02Settings.Household_Contact_Roles_On__c);

        System.assertEquals(RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(), npe03Settings.Open_Opportunity_Behavior__c);
        System.assertEquals([select id from RecordType where sobjecttype = 'Opportunity' limit 1].id, npe03Settings.Record_Type__c);

        System.assertEquals('List Setting', npe04Settings.Reciprocal_Method__c);

        System.assertEquals(true, npe05Settings.Automatic_Affiliation_Creation_Turned_On__c);

        System.assertEquals(true, errorSettings.Store_Errors_On__c);
        System.assertEquals(true, errorSettings.Error_Notifications_On__c);
        System.assertEquals(ERR_Notifier.ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS, errorSettings.Error_Notifications_To__c);

        System.assertEquals(false, addrVerificationSetgs.Enable_Automatic_Verification__c);
        System.assertEquals(false, addrVerificationSetgs.Reject_Ambiguous_Addresses__c);

        System.assertEquals('HH_NameSpec',householdNamingSettings.Implementing_Class__c);
        System.assertEquals(365,allocationsSettings.Rollup_N_Day_Value__c);

        System.assertEquals(50,dataImportSettings.Batch_Size__c);

        System.assertEquals(UserInfo.getOrganizationId(), geSettings.SetupOwnerId);

        System.assertNotEquals(pkgSettings.Id, null, 'A default PackageSettings record should have been created');

    }

    /*********************************************************************************************************
    @description
        Test onInstall applies separate independent install actions
    verify:
        Successful install actions are applied if another install action results in an error
    **********************************************************************************************************/
    @isTest
    private static void testInstallActionsAreIndependent() {
        UTIL_RecordTypeSettingsUpdate_TEST.UpdateSettingsMock mockUpdateSettings =
        new UTIL_RecordTypeSettingsUpdate_TEST.UpdateSettingsMock().throwException();
        UTIL_RecordTypeSettingsUpdate.instance = mockUpdateSettings;

        List<Trigger_Handler__c> triggerHandlers = getTriggerHandlers();
        System.assertEquals(0, triggerHandlers.size(), 'No trigger handler should exist: ' + triggerHandlers);

        Test.testInstall(new STG_InstallScript(), new Version(1,0), false);

        triggerHandlers = getTriggerHandlers();
        System.assert(triggerHandlers.size() > 0, 'Thrigger handler should be successful when Record Type Settings cleanup fails: ' + triggerHandlers);

        List<Error__c> errors = getErrors();
        System.assertEquals(1, errors.size(), 'One exception error should be created for the invalid Record Type settings: ' + errors);
        System.assertEquals('Test Exception', errors[0].Full_Message__c, 'Error message has not been applied correctly.');
    }

    // Test testNewInstallSetsRecurringDonationInstallmentNumber was removed because it tested the
    // POPULATE_RD_INSTALLMENT_NUMBER install action and RD_InstallScript_BATCH, both of which were
    // deleted as part of the RD1 removal.

    /*********************************************************************************************************
    @description
        Test hasErrors() returns true if the logger has at least one exception stored
    verify:
        hasErrors() returns true
    **********************************************************************************************************/
    @isTest
    private static void testErrorLoggerHasErrorsReturnsTrue() {
        STG_InstallScript.ErrorLogger logger = new STG_InstallScript.ErrorLogger(null, ERR_Handler_API.Context.STTG);

        logger.add(new STG_InstallException('Test Exception'));

        System.assert(logger.hasErrors(), 'Logger should return true since it contains one exception');
    }

    /*********************************************************************************************************
    @description
        Test hasErrors() returns false if the logger has no exceptions
    verify:
        hasErrors() returns false
    **********************************************************************************************************/
    @isTest
    private static void testErrorLoggerHasErrorsReturnsFalse() {
        STG_InstallScript.ErrorLogger logger = new STG_InstallScript.ErrorLogger(null, ERR_Handler_API.Context.STTG);

        System.assert(!logger.hasErrors(), 'Logger should return false since it contains no exception');
    }

    /*********************************************************************************************************
    @description
        Test email sent by the logger contains all exceptions
    verify:
        The email body contains exception message and stack trace
    **********************************************************************************************************/
    @isTest
    private static void testErrorLoggerCorrectlyBuildsEmailBody() {
        STG_InstallScript.ErrorLogger logger = new STG_InstallScript.ErrorLogger(null, ERR_Handler_API.Context.STTG);

        logger.add(new STG_InstallException('Test Exception 1'));
        logger.add(new STG_InstallException('Test Exception 2'));

        String emailBody = logger.buildEmailBody();

        String expectedEmailBodyPrefix = Label.stgInstallScriptError +
            '\n\n==========================. \n\nError messages:';

        System.assert(emailBody.startsWith(expectedEmailBodyPrefix), 'The email is not constructed as expected: ' + emailBody);
        System.assert(emailBody.contains('Test Exception 1'), 'The email should contain the first exception: ' + emailBody);
        System.assert(emailBody.contains('Test Exception 2'), 'The email should contain the second exception: ' + emailBody);
    }

    /*********************************************************************************************************
    @description
        Test exceptions on install are emailed and stored as error handler errors
    verify:
        - Exceptions are emailed.
        - Exception is stored as the error sObject record.
    **********************************************************************************************************/
    @isTest
    private static void testExceptionsAreEmailedAndLogged() {
        Integer emailInvocations = Limits.getEmailInvocations();

        UTIL_RecordTypeSettingsUpdate_TEST.UpdateSettingsMock mockUpdateSettings = new UTIL_RecordTypeSettingsUpdate_TEST.UpdateSettingsMock().throwException();
        UTIL_RecordTypeSettingsUpdate.instance = mockUpdateSettings;

        Test.startTest();
        Test.testInstall(new STG_InstallScript(), new Version(1,0), false);
        Integer actualEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        List<Error__c> errors = getErrors();
        System.assertEquals(1, errors.size(), 'One exception error should be created for the invalid Record Type settings: ' + errors);
        System.assertEquals('Test Exception', errors[0].Full_Message__c, 'Error message has not been applied correctly.');

        System.assert(actualEmailInvocations > emailInvocations, 'Email Invocations should increase if the email has been sent');
    }

    /*********************************************************************************************************
    @description
        Test no email is sent and no error is created for the successful install
    verify:
        - No email is sent.
        - No exception is stored as the error sObject record.
    **********************************************************************************************************/
    @isTest
    private static void testNoEmailIsSentOrErrorLoggedOnSuccessfulInstall() {
        Integer emailInvocations = Limits.getEmailInvocations();

        UTIL_RecordTypeSettingsUpdate.instance = new UTIL_RecordTypeSettingsUpdate_TEST.UpdateSettingsMock();

        Test.startTest();
        Test.testInstall(new STG_InstallScript(), new Version(1,0), false);
        Integer actualEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        List<Error__c> errors = getErrors();
        System.assertEquals(0, errors.size(), 'No exception error should be created: ' + errors);

        System.assertEquals(emailInvocations, actualEmailInvocations, 'Email Invocations should not increase');
    }

    /***
    * @description Verifies Oportunity naming Settings Attribution gets updated with
    * API AttributionOptions enum value post push install
    */
    @isTest
    public static void shouldUpdateOppNamingSettingsAttribution() {
        OPP_OpportunityNaming_TEST.setUpOppNamingSettings(new Map<String, Object>{
            'Attribution__c' => System.Label.oppNamingIndividual
        });

        Test.testInstall(new STG_InstallScript(), new Version(1,0), true);

        Opportunity_Naming_Settings__c settings = UTIL_ListCustomSettingsFacade.getMapOppNamingSettings().values()[0];

        System.assertEquals(OPP_AttributionSettings.AttributionOptions.Contact_Donations.name(), settings.Attribution__c,
            'The Attribution should be updated to the AttributionOptions value');
    }

    /***
    * @description Verifies no error is raised when Oportunity naming Settings Attribution
    * is empty post push install
    */
    @isTest
    public static void shouldNotThrowExceptionWhenOppNamingSettingsAttributionIsEmpty() {
        OPP_OpportunityNaming_TEST.setUpOppNamingSettings(new Map<String, Object>{
            'Attribution__c' => null
        });

        Test.testInstall(new STG_InstallScript(), new Version(1,0), true);

        Opportunity_Naming_Settings__c settings = UTIL_ListCustomSettingsFacade.getMapOppNamingSettings().values()[0];

        System.assertEquals(null, settings.Attribution__c, 'The Attribution should stay empty');
    }

    /*********************************************************************************************************
     * Helpers
    **********************************************************************************************************/

    private static void assertTriggerHandlersEqual(List<Trigger_Handler__c> afterScriptConfig, List<Trigger_Handler__c> defaultConfig) {
        afterScriptConfig.sort();
        defaultConfig.sort();

        System.assertEquals(defaultConfig.size(), afterScriptConfig.size(), 'Number of created trigger handlers should match the number of handlers in TDTM_DefaultConfig.');
        for(Integer i = 0; i < defaultConfig.size(); i++) {
            System.assertEquals(afterScriptConfig[i].Class__c, defaultConfig[i].Class__c);
            System.assertEquals(afterScriptConfig[i].Load_Order__c, defaultConfig[i].Load_Order__c);
            System.assertEquals(afterScriptConfig[i].Object__c, defaultConfig[i].Object__c);
            System.assertEquals(afterScriptConfig[i].Active__c, defaultConfig[i].Active__c);
            System.assertEquals(afterScriptConfig[i].Asynchronous__c, defaultConfig[i].Asynchronous__c);
            //split and sort trigger actions so the test doesn't fail for different orders
            List<String> afterTriggerAction = afterScriptConfig[i].Trigger_Action__c.split(';');
            List<String> defaultTriggerAction = defaultConfig[i].Trigger_Action__c.split(';');
            afterTriggerAction.sort();
            defaultTriggerAction.sort();
            System.assertEquals(afterTriggerAction, defaultTriggerAction);
        }
    }

    /*********************************************************************************************************
    @description
        Verify that the Customizable Rollup Settings matches the expected Configuration
    **********************************************************************************************************/
    private static void assertRollupSettingsEqual(Customizable_Rollup_Settings__c expectedConfig) {

        Customizable_Rollup_Settings__c afterScriptConfig = UTIL_CustomSettingsFacade.getOrgCustomizableRollupSettings();

        System.assertEquals(expectedConfig.Customizable_Rollups_Enabled__c, afterScriptConfig.Customizable_Rollups_Enabled__c, 'The settings should match');
        System.assertEquals(expectedConfig.Rollups_Account_Batch_Size__c, afterScriptConfig.Rollups_Account_Batch_Size__c , 'The settings should match');
        System.assertEquals(expectedConfig.Rollups_Contact_Batch_Size__c, afterScriptConfig.Rollups_Contact_Batch_Size__c , 'The settings should match');
        System.assertEquals(expectedConfig.Rollups_Account_SkewMode_Batch_Size__c, afterScriptConfig.Rollups_Account_SkewMode_Batch_Size__c , 'The settings should match');
        System.assertEquals(expectedConfig.Rollups_Contact_SkewMode_Batch_Size__c, afterScriptConfig.Rollups_Contact_SkewMode_Batch_Size__c , 'The settings should match');
        System.assertEquals(expectedConfig.Rollups_Account_Soft_Credit_Batch_Size__c, afterScriptConfig.Rollups_Account_Soft_Credit_Batch_Size__c , 'The settings should match');
        System.assertEquals(expectedConfig.Rollups_Contact_Soft_Credit_Batch_Size__c, afterScriptConfig.Rollups_Contact_Soft_Credit_Batch_Size__c , 'The settings should match');
        System.assertEquals(expectedConfig.Rollups_AcctContactSoftCredit_Batch_Size__c, afterScriptConfig.Rollups_AcctContactSoftCredit_Batch_Size__c , 'The settings should match');
        System.assertEquals(expectedConfig.Rollups_GAU_Batch_Size__c, afterScriptConfig.Rollups_GAU_Batch_Size__c , 'The settings should match');
        System.assertEquals(expectedConfig.Rollups_Skew_Dispatcher_Batch_Size__c, afterScriptConfig.Rollups_Skew_Dispatcher_Batch_Size__c , 'The settings should match');
        System.assertEquals(expectedConfig.Rollups_Limit_on_Attached_Opps_for_Skew__c, afterScriptConfig.Rollups_Limit_on_Attached_Opps_for_Skew__c , 'The settings should match');
        System.assertEquals(expectedConfig.Disable_Related_Records_Filter__c, afterScriptConfig.Disable_Related_Records_Filter__c , 'The settings should match');
        System.assertEquals(expectedConfig.AccountHardCreditNonSkew_Incremental__c, afterScriptConfig.AccountHardCreditNonSkew_Incremental__c , 'The settings should match');
        System.assertEquals(expectedConfig.ContactHardCreditNonSkew_Incremental__c, afterScriptConfig.ContactHardCreditNonSkew_Incremental__c , 'The settings should match');
        System.assertEquals(expectedConfig.LimitRecalculatedRecurringDonations__c, afterScriptConfig.LimitRecalculatedRecurringDonations__c , 'The settings should match');

        System.assertEquals(ROLLUP_BATCH_SIZE, afterScriptConfig.Rollups_AcctContactSoftCredit_Batch_Size__c, 'The setting should be set to the batch size');
    }

    public static void deleteAllCustomSettings() {
        Contacts_And_Orgs_Settings__c npe01Settings = Contacts_And_Orgs_Settings__c.getInstance();
        Households_Settings__c npo02Settings = Households_Settings__c.getInstance();
        Recurring_Donations_Settings__c npe03Settings = Recurring_Donations_Settings__c.getInstance();
        Relationship_Settings__c npe04Settings = Relationship_Settings__c.getInstance();
        Affiliations_Settings__c npe05Settings = Affiliations_Settings__c.getInstance();
        Error_Settings__c errorSettings = Error_Settings__c.getInstance();
        if(npe01Settings.Id != null) delete npe01Settings;
        if(npo02Settings.Id != null) delete npo02Settings;
        if(npe03Settings.Id != null) delete npe03Settings;
        if(npe04Settings.Id != null) delete npe04Settings;
        if(npe05Settings.Id != null) delete npe05Settings;
        if(errorSettings.Id != null) delete errorSettings;
    }


    public static void createSomeDefaultSettings() {
        List<Trigger_Handler__c> handlers = new List<Trigger_Handler__c>();

        //Relationships on Relationship__c
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false,
              Class__c = 'REL_Relationships_TDTM', Load_Order__c = 1, Object__c = 'Relationship__c',
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate;AfterDelete'));

        //Account Management on Contact
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false,
              Class__c = 'ACCT_IndividualAccounts_TDTM', Load_Order__c = 1, Object__c = 'Contact',
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate;AfterDelete'));

        // OpportunityContactRole support
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false,
              Class__c = 'HH_OppContactRoles_TDTM', Load_Order__c = 1, Object__c = 'Opportunity',
              Trigger_Action__c = 'AfterInsert'));

        // HH Object support
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false,
              Class__c = 'HH_HHObject_TDTM', Load_Order__c = 1, Object__c = 'Household__c',
              Trigger_Action__c = 'BeforeUpdate;AfterUpdate'));

        // HH Object contact trigger support
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false,
              Class__c = 'HH_Households_TDTM', Load_Order__c = 0, Object__c = 'Contact',
              Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));

        insert handlers;
    }

    public static void verifyAllSettingsCreated() {
        assertTriggerHandlersEqual(getTriggerHandlers(), TDTM_DefaultConfig.getDefaultRecords());
    }

    private static Trigger_Handler__c[] getTriggerHandlers() {
        return [
            SELECT
                Active__c, Asynchronous__c, Class__c,
                Load_Order__c, Object__c, Trigger_Action__c
            FROM Trigger_Handler__c
        ];
    }

    /*********************************************************************************************************
    @description
        Create a new Rollup With Partial Values Set
    **********************************************************************************************************/
    private static Customizable_Rollup_Settings__c buildRollupSettingsWithPartialValues() {
        return UTIL_CustomSettingsFacade.getRollupSettingsForTests(
            new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                Rollups_Limit_on_Attached_Opps_for_Skew__c = 150,
                Rollups_Account_Batch_Size__c = 20,
                Rollups_GAU_Batch_Size__c = 400,
                Rollups_Account_SkewMode_Batch_Size__c = 100,
                Rollups_Contact_SkewMode_Batch_Size__c = 100,
                Rollups_Contact_Soft_Credit_Batch_Size__c = 100,
                Rollups_Account_Soft_Credit_Batch_Size__c = ROLLUP_BATCH_SIZE,
                Rollups_AcctContactSoftCredit_Batch_Size__c = null
            )
        );
    }

    /*******************************************************************************************************
    * @description Gets errors.
    * @return List<Error__c> The List of errors.
    ********************************************************************************************************/
    public static List<Error__c> getErrors() {
        return [
            SELECT Id, Object_Type__c, Full_Message__c, Stack_Trace__c
            FROM Error__c
        ];
    }

}