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
* @description Install Script for the NPSP package.
*/
global without sharing class STG_InstallScript implements InstallHandler {

    @TestVisible
    private enum InstallAction {
        RUN_NEW_ORG_SCRIPT,
        INSERT_TDTM_DEFAULTS, ABORT_OLD_SCHEDULED_JOBS,
        CLEANUP_RECORD_TYPE_SETTINGS, UPDATE_CAMPAIGN_LIST_REPORT,
        CREATE_DEFAULT_SETTINGS_FOR_UPGRADE,
        CREATE_DEFAULT_SETTINGS_FOR_NEW_INSTALL,
        CREATE_OPP_STAGE_TO_STATE_RECORDS
    }

    public STG_InstallScript() {
    }

    /*******************************************************************************************************
    * @description Runs on package install.
    * @param context The install context.
    * @return void
    */
    global void onInstall(InstallContext context) {
        ErrorLogger logger = new ErrorLogger(context, ERR_Handler_API.Context.STTG);

        // First install of Cumulus
        if (context.previousVersion() == null) {
            // Ensure custom settings that we manage are populated
            executeAction(InstallAction.CREATE_DEFAULT_SETTINGS_FOR_NEW_INSTALL, logger);

            executeAction(InstallAction.RUN_NEW_ORG_SCRIPT, logger);

        // Upgrade of existing Cumulus installation
        } else if (context.isUpgrade() || context.isPush()) {
            // Ensure the any new Custom Settings objects are populated
            executeAction(InstallAction.CREATE_DEFAULT_SETTINGS_FOR_UPGRADE, logger);

            // Insert/Update the TDTM defaults as needed
            executeAction(InstallAction.INSERT_TDTM_DEFAULTS, logger);

        }

        executeAction(InstallAction.ABORT_OLD_SCHEDULED_JOBS, logger);

        // Upgrade from NPSP 3.79
        if (context.previousVersion() == null || context.previousVersion().compareTo(new Version(3, 79)) < 0) {
            executeAction(InstallAction.CLEANUP_RECORD_TYPE_SETTINGS, logger);
        }

        // Upgrade from NPSP 3.112
        if (context.previousVersion() == null || context.previousVersion().compareTo(new Version(3, 112)) < 0) {
            executeAction(InstallAction.UPDATE_CAMPAIGN_LIST_REPORT, logger);
        }

        logger.log();
    }

    private void executeAction(InstallAction action, ErrorLogger logger) {

        Savepoint sp = Database.setSavepoint();

        try {
            if (action == InstallAction.RUN_NEW_ORG_SCRIPT) {
                runNewOrgScript();

            } else if (action == InstallAction.INSERT_TDTM_DEFAULTS) {
                insertTdtmDefaults(null);

            } else if (action == InstallAction.ABORT_OLD_SCHEDULED_JOBS) {
                UTIL_MasterSchedulableHelper.abortOldScheduledJobs();

            } else if (action == InstallAction.CLEANUP_RECORD_TYPE_SETTINGS) {
                UTIL_RecordTypeSettingsUpdate.getInstance().updateSettings();

            } else if (action == InstallAction.UPDATE_CAMPAIGN_LIST_REPORT) {
                updateCampaignListReport();

            } else if (action == InstallAction.CREATE_DEFAULT_SETTINGS_FOR_UPGRADE) {
                populateNamespacePrefix();
                createNewDefaultCustomSettingRecords();

            } else if (action == InstallAction.CREATE_DEFAULT_SETTINGS_FOR_NEW_INSTALL) {
                populateNamespacePrefix();
            } else if (action == InstallAction.CREATE_OPP_STAGE_TO_STATE_RECORDS) {
                createOppStageToStateRecordsIfNecessary();
            }

        } catch(Exception e) {
            Database.rollback(sp);

            logger.add(e);
        }
    }

    /*******************************************************************************************************
    * @description Sets up TDTM in new orgs. Also called by the NPPatch Settings page on page load (i.e., this method
    * runs every single time the NPPatch Settings page is loaded).
    * @return void
    */
    global void runNewOrgScript() {
        insertTdtmDefaults(null);
    }

    /*******************************************************************************************************
    * @description NPSP Version 3.112 changed the report distributed and used for the Campaign Household Mailing
    * List report launched by the HH_CampaignDedupeBTN VF page (from a custom button). The old report previously
    * installed as part of the Households package is not Lightning compatible, requiring a new report.
    * @return void
    */
    private void updateCampaignListReport() {
        Households_Settings__c hs = UTIL_CustomSettingsFacade.getHouseholdsSettings();
        Report r;
        try{
            r = [SELECT Id FROM Report WHERE DeveloperName = 'Campaign_Household_Mailing_List'];
        } catch(QueryException e) {
            // Ignore this error
        }
        if (r != null && hs.Household_Mailing_List_ID__c != r.Id) {
            hs.Household_Mailing_List_ID__c = r.Id;
            update hs;
        }
    }

    /*******************************************************************************************************
    * @description Delegates to TDTM_DefaultConfig.insertDefaults(). Kept for backwards compatibility
    * with existing callers and tests.
    * @return void
    */
    public static void insertTdtmDefaults(List<Trigger_Handler__c> defaultHandlers) {
        TDTM_DefaultConfig.insertDefaults(defaultHandlers);
    }

    /*******************************************************************************************************
    * @description Ensure that any default Custom Settings Records are created for "new" custom settings objects
    * added
    */
    private void createNewDefaultCustomSettingRecords() {
        updateDefaultRollupSettings();
        updateDefaultOrgContactsSettings();
        updateOpportunityNamingSettings();
        createDefaultGiftEntrySettings();
    }

    /***
    * @description Update Opportunity Naming Settings Attribution value to the AttributionOptions API value
    */
    private static void updateOpportunityNamingSettings() {
        List <Opportunity_Naming_Settings__c> oppSettings = new List <Opportunity_Naming_Settings__c>();
        OPP_AttributionSettings attributionSettings = new OPP_AttributionSettings();

        for (Opportunity_Naming_Settings__c ons : UTIL_ListCustomSettingsFacade.getMapOppNamingSettings().values()) {
            ons.Attribution__c = attributionSettings.withSelected(ons.Attribution__c).selectedOption;
            oppSettings.add(ons);
        }

        update oppSettings;
    }

    /*******************************************************************************************************
    * @description Ensure that any default Org Contacts Settings Records are updated for custom settings
    * objects accordingly.
    */
    private static void updateDefaultOrgContactsSettings() {
        Contacts_And_Orgs_Settings__c npe01Settings = UTIL_CustomSettingsFacade.getOrgContactsSettings();
        if (npe01Settings.Contact_Role_for_Organizational_Opps__c == null) {
            npe01Settings.Contact_Role_for_Organizational_Opps__c = UTIL_CustomSettingsFacade.DEFAULT_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT;
            update npe01Settings;
        }
    }

    /*******************************************************************************************************
    * @description Ensure that any default Org Rollup Settigns are updated for custom settings
    * objects accordingly.  There was a swap of custom setting fields to get the account soft credit settings
    * pointed to the corresponding setting
    */
    private static void updateDefaultRollupSettings() {
        Customizable_Rollup_Settings__c rollupSettings = UTIL_CustomSettingsFacade.getOrgCustomizableRollupSettings();
        Boolean isUpdateNeeded = false;
        Decimal currentAccountSoftCreditBatchSize = UTIL_CustomSettingsFacade.DEFAULT_ROLLUP_BATCH_SIZE;

        if (rollupSettings.Rollups_Account_Soft_Credit_Batch_Size__c != null) {
            currentAccountSoftCreditBatchSize = rollupSettings.Rollups_Account_Soft_Credit_Batch_Size__c;
        }

        if (rollupSettings.Rollups_AcctContactSoftCredit_Batch_Size__c == null) {
            rollupSettings.Rollups_AcctContactSoftCredit_Batch_Size__c = currentAccountSoftCreditBatchSize;
            isUpdateNeeded = true;
        }

        if (isUpdateNeeded) {
            update rollupSettings;
        }

    }

    /**
     * @description Create the default gift entry and data import settings records for all new push upgrades
     */
    private static void createDefaultGiftEntrySettings() {
        UTIL_CustomSettingsFacade.getOrgGiftEntrySettings();
        UTIL_CustomSettingsFacade.getOrgDataImportSettings();

    }

    /*******************************************************************************************************
    * @description Make sure a value is set for the namespace prefix custom setting.
    */
    private void populateNamespacePrefix() {
        Package_Settings__c pkgSettings = Package_Settings__c.getOrgDefaults();
        if (pkgSettings.Id == null) {
            pkgSettings.Namespace_Prefix__c = UTIL_Namespace.prefixNamespace('');
            insert pkgSettings;
        }
    }

    /*******************************************************************************************************
    * @description Creates the finalized opp stage to state record based on what value is set as the
    * "Opportunity Stage for When Fully Paid"
    */
    private void createOppStageToStateRecordsIfNecessary() {

        // This is no longer being called in the post install script at all.
        // We will revisit this very soon.
        // There was issues with the upgrade process, so we are unable to
        // get this in before GA.
        List<Metadata.CustomMetadata> metadataToInsert = new List<Metadata.CustomMetadata>();
        Map<String, Object> params = new Map<String, Object>();

        metadataToInsert = Opp_StageMappingCMT.createPledgedOppStageToStateRecord(metadataToInsert);
        metadataToInsert = Opp_StageMappingCMT.createFinalizedOppStageToStateRecord(metadataToInsert);

        if (!metadataToInsert.isEmpty()) {
            Opp_StageMappingCMT.deployOppStageToStateMetadata(metadataToInsert, params);
        }
    }

    /*******************************************************************************************************
    * @description Collects exceptions. Logs exceptions by sending an email and processing error via ERR_Handler.
    */
    public class ErrorLogger {
        /** @description The install context. */
        InstallContext installContext;

        /** @description The error handler context. */
        ERR_Handler_API.Context errContext;

        /** @description The list of exceptions. */
        List<Exception> exceptions = new List<Exception>();

        /*******************************************************************************************************
        * @description The constructor
        * @param installContext The install context
        * @param errContext The error handler context
        */
        public ErrorLogger(InstallContext installContext, ERR_Handler_API.Context errContext) {
            this.installContext = installContext;
            this.errContext = errContext;
        }

        /*******************************************************************************************************
        * @description Returns true if the logger has at least one exception stored
        * @return Boolean
        */
        public Boolean hasErrors() {
            return !exceptions.isEmpty();
        }

        /*******************************************************************************************************
        * @description Adds the exception to the list of exceptions
        * @param e The Exception
        * @return void
        */
        public void add(Exception e) {
            if (e != null) {
                exceptions.add(e);
            }
        }

        /*******************************************************************************************************
        * @description Logs the exception by sending an email and processing the errors via ERR_Handler
        * @return void
        */
        public void log() {
            if (!hasErrors()) {
                return;
            }

            sendEmail();
            ERR_Handler.processErrors(exceptions, errContext);
        }

        /*******************************************************************************************************
        * @description Sends an email to the user installing the package notifying them about failed installation steps.
        * @return void
        */
        private void sendEmail() {
            try {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setUseSignature(false);
                mail.setReplyTo(ERR_Notifier.EMAIL_REPLY_TO);
                mail.setSenderDisplayName(ERR_Notifier.EMAIL_SENDER_NAME);
                mail.setSubject('NPPatch Install Errors');

                mail.setPlainTextBody(buildEmailBody());

                mail.setToAddresses(new String[] { ERR_Notifier.EMAIL_SYSTEM_ERRORS_TO, getUserEmail() });

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

            } catch(Exception e) {
                //Nothing to do here, as we don't want the install script to fail because emails could not be sent.
            }

        }

        /*******************************************************************************************************
        * @description Retrieves the installing user email
        * @return String
        */
        private String getUserEmail() {
            String userEmail = [SELECT Id, Email FROM User WHERE Id =:installContext.installerID()].Email;
            return UTIL_Namespace.sandboxEmailToRealEmail(userEmail);
        }

        /*******************************************************************************************************
        * @description Builds email body by displaying exception messages and stack traces.
        * @return String
        */
        @TestVisible
        private String buildEmailBody() {
            String bodyString = Label.stgInstallScriptError;

            bodyString += String.format(
                '\n\n==========================. \n\nError message{0}:',
                new String[] { exceptions.size() == 1 ? '' : 's'}
            );

            for (Exception e : exceptions) {
                bodyString += '\n' + e.getMessage() +
                    '\nError stack trace: \n' + e.getStackTraceString() +
                    '\n\n';
            }

            return bodyString;
        }

    }
}
