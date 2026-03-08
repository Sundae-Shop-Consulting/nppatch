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
        try {
            upsert existing;
        } catch (Exception ex) {
            AuraHandledException ahe = new AuraHandledException(ex.getMessage());
            ahe.setMessage(ex.getMessage());
            throw ahe;
        }
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
                UTIL_Namespace.prefixNamespace(sObjectApiName)
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
                UTIL_Namespace.prefixNamespace(sObjectApiName)
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
                UTIL_Namespace.prefixNamespace(fieldApiName)
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

    // ─── Initialization ──────────────────────────────────────────────────

    /**
     * @description Ensures org-level Custom Settings records exist with defaults
     * for only the specified objects. Called before cacheable @wire getSettings
     * calls, since the facade methods perform DML to create missing records.
     * @param settingsObjectNames List of Custom Settings API names to ensure
     */
    @AuraEnabled
    public static void ensureSettingsExist(List<String> settingsObjectNames) {
        for (String settingsObjectName : settingsObjectNames) {
            switch on settingsObjectName {
                when 'Contacts_And_Orgs_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgContactsSettings();
                }
                when 'Households_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgHouseholdsSettings();
                }
                when 'Household_Naming_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgHouseholdNamingSettings();
                }
                when 'Affiliations_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgAffiliationsSettings();
                }
                when 'Relationship_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgRelationshipSettings();
                }
                when 'Allocations_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgAllocationsSettings();
                }
                when 'Customizable_Rollup_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgCustomizableRollupSettings();
                }
                when 'Error_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgErrorSettings();
                }
                when 'Recurring_Donations_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgRecurringDonationsSettings();
                }
                when 'Levels_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgLevelsSettings();
                }
                when 'Addr_Verification_Settings__c' {
                    UTIL_CustomSettingsFacade.getOrgAddressVerificationSettings();
                }
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
                UTIL_Namespace.prefixNamespace(settingsObjectName)
            );
        }
        SObject record = sot.newSObject();
        for (String fieldName : fieldValues.keySet()) {
            if (fieldName.equalsIgnoreCase('Id') || fieldName.equalsIgnoreCase('attributes')) {
                continue;
            }
            record.put(fieldName, fieldValues.get(fieldName));
        }
        try {
            insert record;
        } catch (Exception ex) {
            AuraHandledException ahe = new AuraHandledException(ex.getMessage());
            ahe.setMessage(ex.getMessage());
            throw ahe;
        }
        return record.Id;
    }

    /**
     * @description Updates an existing list custom setting record. Admin only.
     * @param settingsObjectName API name of the list custom setting
     * @param recordId The Id of the record to update
     * @param fieldValues Map of field API names to new values
     */
    @AuraEnabled
    public static void updateListSetting(String settingsObjectName, Id recordId, Map<String, Object> fieldValues) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();
        validateListSettingsName(settingsObjectName);

        Schema.SObjectType sot = Schema.getGlobalDescribe().get(settingsObjectName);
        if (sot == null) {
            sot = Schema.getGlobalDescribe().get(
                UTIL_Namespace.prefixNamespace(settingsObjectName)
            );
        }
        SObject record = sot.newSObject(recordId);
        for (String fieldName : fieldValues.keySet()) {
            if (fieldName.equalsIgnoreCase('Id') || fieldName.equalsIgnoreCase('attributes')) {
                continue;
            }
            record.put(fieldName, fieldValues.get(fieldName));
        }
        try {
            update record;
        } catch (Exception ex) {
            AuraHandledException ahe = new AuraHandledException(ex.getMessage());
            ahe.setMessage(ex.getMessage());
            throw ahe;
        }
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
                UTIL_Namespace.prefixNamespace(sObjectApiName)
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
        return fields;
    }

    /**
     * @description Returns active General Accounting Unit records for picklist selection.
     * @return List of maps with 'label' (Name) and 'value' (Id) keys
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getGAUOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (General_Accounting_Unit__c gau : [
            SELECT Id, Name FROM General_Accounting_Unit__c
            WHERE Active__c = true
            ORDER BY Name
            LIMIT 1000
        ]) {
            options.add(new Map<String, String>{
                'label' => gau.Name,
                'value' => gau.Id
            });
        }
        return options;
    }

    /**
     * @description Searches active users by name for error notification recipient selection.
     * @param searchTerm Partial name to search for (minimum 2 characters)
     * @return List of maps with 'label' (Name + Profile), 'value' (User Id), 'sublabel' (Username)
     */
    @AuraEnabled
    public static List<Map<String, String>> searchUsers(String searchTerm) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();
        List<Map<String, String>> results = new List<Map<String, String>>();
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return results;
        }
        String liketerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        for (User u : [
            SELECT Id, Name, Username, Profile.Name
            FROM User
            WHERE IsActive = true AND Name LIKE :liketerm
            ORDER BY Name
            LIMIT 20
        ]) {
            results.add(new Map<String, String>{
                'label' => u.Name,
                'value' => u.Id,
                'sublabel' => u.Profile.Name + ' \u2022 ' + u.Username
            });
        }
        return results;
    }

    /**
     * @description Searches Chatter groups by name for error notification recipient selection.
     * @param searchTerm Partial name to search for (minimum 2 characters)
     * @return List of maps with 'label' (Name), 'value' (Group Id), 'sublabel' (Description)
     */
    @AuraEnabled
    public static List<Map<String, String>> searchChatterGroups(String searchTerm) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();
        List<Map<String, String>> results = new List<Map<String, String>>();
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return results;
        }
        String liketerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        for (CollaborationGroup g : [
            SELECT Id, Name, Description, MemberCount
            FROM CollaborationGroup
            WHERE Name LIKE :liketerm AND IsArchived = false
            ORDER BY Name
            LIMIT 20
        ]) {
            String groupDesc = g.Description != null ? g.Description.abbreviate(60) : '';
            String sublabel = String.valueOf(g.MemberCount) + ' members';
            if (String.isNotBlank(groupDesc)) {
                sublabel += ' \u2022 ' + groupDesc;
            }
            results.add(new Map<String, String>{
                'label' => g.Name,
                'value' => g.Id,
                'sublabel' => sublabel
            });
        }
        return results;
    }

    /**
     * @description Resolves an error notification recipient value to a display label.
     * @param recipientValue The stored value (User Id, Chatter Group Id, or 'All Sys Admins')
     * @return Map with 'label' and 'type' keys
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> resolveErrorRecipient(String recipientValue) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();
        Map<String, String> result = new Map<String, String>();

        if (String.isBlank(recipientValue) || recipientValue == 'All Sys Admins') {
            result.put('type', 'allSysAdmins');
            result.put('label', 'All System Administrators');
            return result;
        }

        // Check if it's a User ID (005 prefix)
        if (recipientValue instanceof Id && recipientValue.startsWith('005')) {
            result.put('type', 'user');
            List<User> users = [SELECT Name, Username FROM User WHERE Id = :recipientValue LIMIT 1];
            if (!users.isEmpty()) {
                result.put('label', users[0].Name);
                result.put('sublabel', users[0].Username);
            } else {
                result.put('label', '(Unknown User)');
            }
            return result;
        }

        // Check if it's a Chatter Group ID (0F9 prefix)
        if (recipientValue instanceof Id) {
            result.put('type', 'chatterGroup');
            List<CollaborationGroup> groups = [SELECT Name FROM CollaborationGroup WHERE Id = :recipientValue LIMIT 1];
            if (!groups.isEmpty()) {
                result.put('label', groups[0].Name);
            } else {
                result.put('label', '(Unknown Chatter Group)');
            }
            return result;
        }

        result.put('type', 'allSysAdmins');
        result.put('label', 'All System Administrators');
        return result;
    }

    /**
     * @description Returns field describes for multiple SObjects in a single call.
     * @param sObjectApiNames List of SObject API names
     * @return Map of SObject name → field describe list
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getMultiObjectFieldDescribes(List<String> sObjectApiNames) {
        Map<String, List<Map<String, String>>> result = new Map<String, List<Map<String, String>>>();
        for (String apiName : sObjectApiNames) {
            try {
                result.put(apiName, getFieldDescribes(apiName));
            } catch (Exception ex) {
                result.put(apiName, new List<Map<String, String>>());
            }
        }
        return result;
    }

    // ─── Trigger Handler Typeahead ──────────────────────────────────────

    /**
     * @description Searches SObject API names for the trigger handler Object typeahead.
     * @param searchTerm Partial name to search for (minimum 2 characters)
     * @return List of maps with 'label' (Label) and 'value' (QualifiedApiName)
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchSObjects(String searchTerm) {
        List<Map<String, String>> results = new List<Map<String, String>>();
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return results;
        }
        String likeTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        for (EntityDefinition ed : [
            SELECT QualifiedApiName, Label
            FROM EntityDefinition
            WHERE QualifiedApiName LIKE :likeTerm
            AND IsCustomizable = true
            ORDER BY QualifiedApiName
            LIMIT 20
        ]) {
            results.add(new Map<String, String>{
                'label' => ed.Label,
                'value' => ed.QualifiedApiName
            });
        }
        return results;
    }

    /**
     * @description Searches Apex class names for the trigger handler Class typeahead.
     * @param searchTerm Partial name to search for (minimum 2 characters)
     * @return List of maps with 'label' (Name) and 'value' (Name)
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchApexClasses(String searchTerm) {
        List<Map<String, String>> results = new List<Map<String, String>>();
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return results;
        }
        String likeTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        for (ApexClass c : [
            SELECT Name, NamespacePrefix
            FROM ApexClass
            WHERE Name LIKE :likeTerm
            ORDER BY Name
            LIMIT 20
        ]) {
            String displayName = c.Name;
            if (String.isNotBlank(c.NamespacePrefix)) {
                displayName = c.NamespacePrefix + '.' + c.Name;
            }
            results.add(new Map<String, String>{
                'label' => displayName,
                'value' => c.Name
            });
        }
        return results;
    }

    /**
     * @description Validates that an Apex class implements TDTM_Runnable (the trigger handler interface).
     * @param className Name of the Apex class to validate
     * @return true if the class extends TDTM_Runnable
     */
    @AuraEnabled
    public static Boolean validateTriggerHandlerClass(String className) {
        if (String.isBlank(className)) {
            return false;
        }
        // Try current namespace first, then unqualified
        String ns = UTIL_Namespace.getNamespace();
        Type classType = String.isNotBlank(ns) ? Type.forName(ns, className) : null;
        if (classType == null) {
            classType = Type.forName(className);
        }
        if (classType == null) {
            return false;
        }
        try {
            Object instance = classType.newInstance();
            return instance instanceof TDTM_Runnable;
        } catch (Exception ex) {
            return false;
        }
    }

    // ─── Address Verification ──────────────────────────────────────────

    private static final Set<String> VALIDATOR_EXCLUSIONS = new Set<String>{
        'ADDR_IValidator', 'ADDR_Validator', 'ADDR_Validator_REST'
    };

    /**
     * @description Discovers available address verification service classes
     * by querying ApexClass metadata and checking for ADDR_IValidator implementations.
     * Returns a list of maps with className, serviceName, and defaultUrl keys.
     * @return List of maps describing each available validator
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAddressValidators() {
        List<Map<String, String>> validators = new List<Map<String, String>>();

        String addrLikeClause = 'ADDR%';
        ApexClass[] classes = [
            SELECT Name, NamespacePrefix
            FROM ApexClass
            WHERE Name LIKE :addrLikeClause
        ];

        for (ApexClass c : classes) {
            String upperName = c.Name.toUpperCase();
            if (VALIDATOR_EXCLUSIONS.contains(c.Name)
                || upperName.endsWith('TEST')
                || upperName.endsWith('CTRL')
                || upperName.endsWith('TDTM')
                || upperName.endsWith('BATCH')
                || upperName.endsWith('SCHED')) {
                continue;
            }
            Type classType = Type.forName(c.NamespacePrefix, c.Name);
            if (classType != null) {
                try {
                    Object classInstance = classType.newInstance();
                    if (classInstance instanceof ADDR_IValidator) {
                        ADDR_IValidator validator = (ADDR_IValidator) classInstance;
                        validators.add(new Map<String, String>{
                            'className' => c.Name,
                            'serviceName' => validator.getServiceName(),
                            'defaultUrl' => validator.getDefaultURL()
                        });
                    }
                } catch (Exception ex) {
                    // Skip classes that fail to instantiate
                }
            }
        }
        return validators;
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
            when 'Addr_Verification_Settings__c' {
                return UTIL_CustomSettingsFacade.getOrgAddressVerificationSettings();
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
