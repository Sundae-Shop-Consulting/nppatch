/**
 * @description Apex controller for the LWC-based NPPatch Settings page.
 * Provides generic read/save for Custom Settings objects, restricted to
 * an explicit allow-list.
 */
public with sharing class NppatchSettingsController {

    /**
     * @description Returns the org-level Custom Settings record for the given object.
     * @param settingsObjectName API name of the Custom Settings object
     * @return The org-level record as an SObject
     */
    @AuraEnabled(cacheable=true)
    public static SObject getSettings(String settingsObjectName) {
        return getSettingsRecord(settingsObjectName);
    }

    /**
     * @description Saves field values to the org-level Custom Settings record.
     * Only admin users may call this method.
     * @param settingsObjectName API name of the Custom Settings object
     * @param fieldValues Map of field API names to new values
     */
    @AuraEnabled
    public static void saveSettings(String settingsObjectName, Map<String, Object> fieldValues) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();

        SObject existing = getSettingsRecord(settingsObjectName);
        for (String fieldName : fieldValues.keySet()) {
            if (fieldName.equalsIgnoreCase('Id') || fieldName.equalsIgnoreCase('attributes')) {
                continue;
            }
            existing.put(fieldName, fieldValues.get(fieldName));
        }
        upsert existing;
    }

    /**
     * @description Returns record type options (label/value pairs) for the given SObject type.
     * @param sObjectApiName API name of the SObject (e.g. 'Opportunity')
     * @return List of maps with 'label' and 'value' keys
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRecordTypeOptions(String sObjectApiName) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(sObjectApiName);
        if (sot == null) {
            sot = Schema.getGlobalDescribe().get(
                UTIL_Namespace.StrTokenNSPrefix(sObjectApiName)
            );
        }
        if (sot == null) {
            AuraHandledException e = new AuraHandledException(
                'Invalid SObject type: ' + sObjectApiName
            );
            e.setMessage('Invalid SObject type: ' + sObjectApiName);
            throw e;
        }
        return UTIL_RecordTypes.getRecordTypesForLightningSelect(sot);
    }

    /**
     * @description Returns picklist entry label/value pairs for a given SObject field.
     * @param sObjectApiName API name of the SObject (e.g. 'Opportunity')
     * @param fieldApiName API name of the field (e.g. 'Type')
     * @return List of maps with 'label' and 'value' keys
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistOptions(String sObjectApiName, String fieldApiName) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(sObjectApiName);
        if (sot == null) {
            sot = Schema.getGlobalDescribe().get(
                UTIL_Namespace.StrTokenNSPrefix(sObjectApiName)
            );
        }
        if (sot == null) {
            AuraHandledException e = new AuraHandledException(
                'Invalid SObject type: ' + sObjectApiName
            );
            e.setMessage('Invalid SObject type: ' + sObjectApiName);
            throw e;
        }
        Schema.SObjectField field = sot.getDescribe().fields.getMap().get(fieldApiName);
        if (field == null) {
            field = sot.getDescribe().fields.getMap().get(
                UTIL_Namespace.StrTokenNSPrefix(fieldApiName)
            );
        }
        if (field == null) {
            AuraHandledException e = new AuraHandledException(
                'Invalid field: ' + fieldApiName
            );
            e.setMessage('Invalid field: ' + fieldApiName);
            throw e;
        }
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Schema.PicklistEntry pe : field.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                options.add(new Map<String, String>{
                    'label' => pe.getLabel(),
                    'value' => pe.getValue()
                });
            }
        }
        return options;
    }

    /**
     * @description Returns whether the current user has admin permissions.
     * @return true if the running user is a System Administrator
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isAdmin() {
        return STG_Panel.runningUserIsAdmin();
    }

    // ─── Batch Execution ────────────────────────────────────────────────

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
            when else {
                AuraHandledException e = new AuraHandledException(
                    'Invalid batch name: ' + batchName
                );
                e.setMessage('Invalid batch name: ' + batchName);
                throw e;
            }
        }
    }

    // ─── List Custom Settings CRUD ──────────────────────────────────────

    private static final Set<String> ALLOWED_LIST_SETTINGS = new Set<String>{
        'Relationship_Lookup__c',
        'Relationship_Auto_Create__c',
        'Opportunity_Naming_Settings__c',
        'Payment_Field_Mapping_Settings__c'
    };

    /**
     * @description Returns all records for a list custom setting.
     * @param settingsObjectName API name of the list custom setting
     * @return List of SObject records
     */
    @AuraEnabled(cacheable=true)
    public static List<SObject> getListSettings(String settingsObjectName) {
        validateListSettingsName(settingsObjectName);

        switch on settingsObjectName {
            when 'Relationship_Lookup__c' {
                return UTIL_ListCustomSettingsFacade.getMapRelationshipLookupSettings().values();
            }
            when 'Relationship_Auto_Create__c' {
                return UTIL_ListCustomSettingsFacade.getMapRelationshipAutoCreateSettings().values();
            }
            when 'Opportunity_Naming_Settings__c' {
                return UTIL_ListCustomSettingsFacade.getMapOppNamingSettings().values();
            }
            when 'Payment_Field_Mapping_Settings__c' {
                return UTIL_ListCustomSettingsFacade.getMapPaymentFieldMappingSettings().values();
            }
            when else {
                return new List<SObject>();
            }
        }
    }

    /**
     * @description Creates a new list custom setting record. Admin only.
     * @param settingsObjectName API name of the list custom setting
     * @param fieldValues Map of field API names to values
     * @return The Id of the created record
     */
    @AuraEnabled
    public static Id createListSetting(String settingsObjectName, Map<String, Object> fieldValues) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();
        validateListSettingsName(settingsObjectName);

        Schema.SObjectType sot = Schema.getGlobalDescribe().get(settingsObjectName);
        if (sot == null) {
            sot = Schema.getGlobalDescribe().get(
                UTIL_Namespace.StrTokenNSPrefix(settingsObjectName)
            );
        }
        SObject record = sot.newSObject();
        for (String fieldName : fieldValues.keySet()) {
            if (fieldName.equalsIgnoreCase('Id') || fieldName.equalsIgnoreCase('attributes')) {
                continue;
            }
            record.put(fieldName, fieldValues.get(fieldName));
        }
        insert record;
        return record.Id;
    }

    /**
     * @description Deletes a list custom setting record by Id. Admin only.
     * @param settingsObjectName API name of the list custom setting (for validation)
     * @param recordId The Id of the record to delete
     */
    @AuraEnabled
    public static void deleteListSetting(String settingsObjectName, Id recordId) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();
        validateListSettingsName(settingsObjectName);

        SObject record = recordId.getSObjectType().newSObject(recordId);
        delete record;
    }

    // ─── Trigger Handler CRUD ───────────────────────────────────────────

    /**
     * @description Returns all Trigger Handler records.
     * @return List of Trigger_Handler__c records ordered by Object and Load Order
     */
    @AuraEnabled(cacheable=true)
    public static List<Trigger_Handler__c> getTriggerHandlers() {
        return [
            SELECT Id, Object__c, Class__c, Load_Order__c, Trigger_Action__c,
                   Active__c, Asynchronous__c, User_Managed__c, Usernames_to_Exclude__c
            FROM Trigger_Handler__c
            ORDER BY Object__c, Load_Order__c
        ];
    }

    /**
     * @description Creates a new Trigger Handler record. Admin only.
     * @param fieldValues Map of field API names to values
     * @return The Id of the created record
     */
    @AuraEnabled
    public static Id createTriggerHandler(Map<String, Object> fieldValues) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();

        Trigger_Handler__c handler = new Trigger_Handler__c();
        for (String fieldName : fieldValues.keySet()) {
            if (fieldName.equalsIgnoreCase('Id') || fieldName.equalsIgnoreCase('attributes')) {
                continue;
            }
            handler.put(fieldName, fieldValues.get(fieldName));
        }
        handler.User_Managed__c = true;
        insert handler;
        return handler.Id;
    }

    /**
     * @description Deletes a Trigger Handler record by Id. Admin only.
     * @param recordId The Id of the Trigger_Handler__c record to delete
     */
    @AuraEnabled
    public static void deleteTriggerHandler(Id recordId) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();
        delete [SELECT Id FROM Trigger_Handler__c WHERE Id = :recordId];
    }

    /**
     * @description Returns field describe info for building dynamic field pickers.
     * @param sObjectApiName API name of the SObject
     * @return List of maps with label, value, and type keys
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getFieldDescribes(String sObjectApiName) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(sObjectApiName);
        if (sot == null) {
            sot = Schema.getGlobalDescribe().get(
                UTIL_Namespace.StrTokenNSPrefix(sObjectApiName)
            );
        }
        if (sot == null) {
            AuraHandledException e = new AuraHandledException(
                'Invalid SObject type: ' + sObjectApiName
            );
            e.setMessage('Invalid SObject type: ' + sObjectApiName);
            throw e;
        }
        List<Map<String, String>> fields = new List<Map<String, String>>();
        for (Schema.SObjectField field : sot.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            fields.add(new Map<String, String>{
                'label' => dfr.getLabel(),
                'value' => dfr.getName(),
                'type' => String.valueOf(dfr.getType())
            });
        }
        fields.sort();
        return fields;
    }

    // ─── Private Helpers ────────────────────────────────────────────────

    private static void validateListSettingsName(String settingsObjectName) {
        if (!ALLOWED_LIST_SETTINGS.contains(settingsObjectName)) {
            AuraHandledException e = new AuraHandledException(
                'Invalid list settings object: ' + settingsObjectName
            );
            e.setMessage('Invalid list settings object: ' + settingsObjectName);
            throw e;
        }
    }

    /**
     * @description Resolves the correct org-level Custom Settings record.
     * Throws AuraHandledException for any object name not in the allow-list.
     */
    private static SObject getSettingsRecord(String settingsObjectName) {
        switch on settingsObjectName {
            when 'Contacts_And_Orgs_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgContactsSettings();
            }
            when 'Households_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgHouseholdsSettings();
            }
            when 'Household_Naming_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgHouseholdNamingSettings();
            }
            when 'Affiliations_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgAffiliationsSettings();
            }
            when 'Relationship_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgRelationshipSettings();
            }
            when 'Allocations_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgAllocationsSettings();
            }
            when 'Customizable_Rollup_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgCustomizableRollupSettings();
            }
            when 'Error_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgErrorSettings();
            }
            when 'Recurring_Donations_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgRecurringDonationsSettings();
            }
            when 'Levels_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgLevelsSettings();
            }
            when else {
                AuraHandledException e = new AuraHandledException(
                    'Invalid settings object: ' + settingsObjectName
                );
                e.setMessage('Invalid settings object: ' + settingsObjectName);
                throw e;
            }
        }
    }
}
