public with sharing class BulkProcessController {

    /**
     * @description Executes a named batch job. Admin only.
     * @param batchName Identifier for the batch to run
     * @return The AsyncApexJob Id, or null for internally-managed jobs
     */
    @AuraEnabled
    public static Id runBatch(String batchName) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();

        switch on batchName {
            when 'rollupBatch' {
                for (CRLP_RollupProcessingOptions.RollupType jobType : new List<CRLP_RollupProcessingOptions.RollupType>{
                    CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                    CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
                    CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit,
                    CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit,
                    CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit,
                    CRLP_RollupProcessingOptions.RollupType.RecurringDonations
                }) {
                    CRLP_RollupBatch_SVC.executeBatchRollupJob(
                        jobType, CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode);
                }
                return null;
            }
            when 'alloBatch' {
                CRLP_RollupBatch_SVC.executeBatchRollupJob(
                    CRLP_RollupProcessingOptions.RollupType.GAU,
                    CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode);
                return null;
            }
            when 'makeDefaultAllocations' {
                return Database.executeBatch(new ALLO_MakeDefaultAllocations_BATCH());
            }
            when 'createPayments' {
                return Database.executeBatch(new PMT_PaymentCreator_BATCH(), 200);
            }
            when 'refreshHouseholdData' {
                HouseholdNamingService.refreshAllHouseholdNaming(false);
                return null;
            }
            when 'oppNamingBatch' {
                return Database.executeBatch(new OPP_OpportunityNaming_BATCH(), 200);
            }
            when 'updatePrimaryContact' {
                return Database.executeBatch(new OPP_PrimaryContact_BATCH(), 200);
            }
            when 'lvlAssignBatch' {
                new LVL_LevelAssign_SCHED().runBatch();
                return null;
            }
            when 'primaryContactRoleMerge' {
                return Database.executeBatch(new OPP_PrimaryContactRoleMerge_BATCH(), 2000);
            }
            when 'resetTriggerHandlers' {
                TDTM_DefaultConfig.insertDefaults(null);
                return null;
            }
            when 'rescheduleJobs' {
                UTIL_MasterSchedulableHelper.abortOldScheduledJobs();
                UTIL_MasterSchedulableHelper.setScheduledJobs();
                return null;
            }
            when else {
                AuraHandledException e = new AuraHandledException(
                    'Invalid batch name: ' + batchName
                );
                e.setMessage('Invalid batch name: ' + batchName);
                throw e;
            }
        }
    }
}
