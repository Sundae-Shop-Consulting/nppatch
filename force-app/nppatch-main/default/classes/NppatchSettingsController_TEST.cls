@isTest
private with sharing class NppatchSettingsController_TEST {

    // ─── getSettings ────────────────────────────────────────────────────

    @isTest
    private static void shouldReturnHouseholdsSettings() {
        Households_Settings__c expected = UTIL_CustomSettingsFacade.getOrgHouseholdsSettings();

        Test.startTest();
        SObject result = NppatchSettingsController.getSettings('Households_Settings__c');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a settings record');
        System.assertEquals(
            expected.Membership_Grace_Period__c,
            (Decimal) result.get('Membership_Grace_Period__c'),
            'Grace period should match'
        );
    }

    @isTest
    private static void shouldReturnCustomizableRollupSettings() {
        Customizable_Rollup_Settings__c expected =
            UTIL_CustomSettingsFacade.getOrgCustomizableRollupSettings();

        Test.startTest();
        SObject result = NppatchSettingsController.getSettings('Customizable_Rollup_Settings__c');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a settings record');
    }

    @isTest
    private static void shouldReturnAllAllowedSettings() {
        List<String> allowedObjects = new List<String>{
            'Contacts_And_Orgs_Settings__c',
            'Households_Settings__c',
            'Household_Naming_Settings__c',
            'Affiliations_Settings__c',
            'Relationship_Settings__c',
            'Allocations_Settings__c',
            'Customizable_Rollup_Settings__c',
            'Error_Settings__c',
            'Recurring_Donations_Settings__c',
            'Levels_Settings__c',
            'Addr_Verification_Settings__c'
        };

        Test.startTest();
        for (String objName : allowedObjects) {
            SObject result = NppatchSettingsController.getSettings(objName);
            System.assertNotEquals(null, result, 'Should return settings for ' + objName);
        }
        Test.stopTest();
    }

    @isTest
    private static void shouldThrowForDisallowedSettingsObject() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.getSettings('Contact');
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for disallowed object');
        System.assert(
            errorMessage.contains('Invalid settings object'),
            'Error should mention invalid settings object: ' + errorMessage
        );
    }

    @isTest
    private static void shouldThrowForNullSettingsObject() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.getSettings(null);
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for null object name');
    }

    // ─── saveSettings ───────────────────────────────────────────────────

    @isTest
    private static void shouldSaveHouseholdsSettings() {
        UTIL_CustomSettingsFacade.getOrgHouseholdsSettings();

        Map<String, Object> fieldValues = new Map<String, Object>{
            'Membership_Grace_Period__c' => 45
        };

        Test.startTest();
        NppatchSettingsController.saveSettings('Households_Settings__c', fieldValues);
        Test.stopTest();

        Households_Settings__c updated = Households_Settings__c.getOrgDefaults();
        System.assertEquals(
            45,
            updated.Membership_Grace_Period__c,
            'Grace period should be updated to 45'
        );
    }

    @isTest
    private static void saveShouldIgnoreIdAndAttributes() {
        UTIL_CustomSettingsFacade.getOrgHouseholdsSettings();

        Map<String, Object> fieldValues = new Map<String, Object>{
            'Id' => '000000000000000',
            'attributes' => 'something',
            'Membership_Grace_Period__c' => 60
        };

        Test.startTest();
        NppatchSettingsController.saveSettings('Households_Settings__c', fieldValues);
        Test.stopTest();

        Households_Settings__c updated = Households_Settings__c.getOrgDefaults();
        System.assertEquals(
            60,
            updated.Membership_Grace_Period__c,
            'Grace period should be updated despite Id/attributes in input'
        );
    }

    @isTest
    private static void saveShouldThrowForInvalidObject() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.saveSettings('Contact', new Map<String, Object>());
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for disallowed object');
    }

    // ─── getRecordTypeOptions ───────────────────────────────────────────

    @isTest
    private static void shouldReturnRecordTypeOptions() {
        Test.startTest();
        List<Map<String, String>> options =
            NppatchSettingsController.getRecordTypeOptions('Opportunity');
        Test.stopTest();

        System.assertNotEquals(null, options, 'Should return a list (possibly empty)');
    }

    @isTest
    private static void shouldThrowForInvalidSObjectType() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.getRecordTypeOptions('NotARealObject__x');
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for invalid SObject type');
    }

    // ─── getPicklistOptions ─────────────────────────────────────────────

    @isTest
    private static void shouldReturnPicklistOptions() {
        Test.startTest();
        List<Map<String, String>> options =
            NppatchSettingsController.getPicklistOptions('Opportunity', 'StageName');
        Test.stopTest();

        System.assert(options.size() > 0, 'Should return at least one picklist value for Opportunity.StageName');
        System.assertNotEquals(null, options[0].get('label'), 'Each option should have a label');
        System.assertNotEquals(null, options[0].get('value'), 'Each option should have a value');
    }

    @isTest
    private static void shouldThrowForInvalidPicklistObject() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.getPicklistOptions('NotARealObject__x', 'StageName');
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for invalid SObject');
        System.assert(errorMessage.contains('Invalid SObject type'), errorMessage);
    }

    @isTest
    private static void shouldThrowForInvalidPicklistField() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.getPicklistOptions('Opportunity', 'NotARealField__x');
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for invalid field');
        System.assert(errorMessage.contains('Invalid field'), errorMessage);
    }

    // ─── isAdmin ────────────────────────────────────────────────────────

    @isTest
    private static void shouldReturnAdminStatus() {
        Test.startTest();
        Boolean result = NppatchSettingsController.isAdmin();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a boolean value');
    }

    // ─── ensureSettingsExist ────────────────────────────────────────────

    @isTest
    private static void shouldEnsureSettingsExist() {
        List<String> settingsNames = new List<String>{
            'Contacts_And_Orgs_Settings__c',
            'Households_Settings__c',
            'Household_Naming_Settings__c',
            'Affiliations_Settings__c',
            'Relationship_Settings__c',
            'Allocations_Settings__c',
            'Customizable_Rollup_Settings__c',
            'Error_Settings__c',
            'Recurring_Donations_Settings__c',
            'Levels_Settings__c',
            'Addr_Verification_Settings__c'
        };

        Test.startTest();
        NppatchSettingsController.ensureSettingsExist(settingsNames);
        Test.stopTest();

        // Verify the facade methods ran without error — the settings are cached
        // in memory and may not have a persisted Id in test context
        System.assertNotEquals(null, UTIL_CustomSettingsFacade.getOrgContactsSettings(),
            'Contacts_And_Orgs_Settings__c should be accessible');
        System.assertNotEquals(null, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings(),
            'Households_Settings__c should be accessible');
    }

    @isTest
    private static void ensureSettingsExistShouldIgnoreUnknownObjects() {
        // Should not throw for unrecognized names — they're just skipped
        Test.startTest();
        NppatchSettingsController.ensureSettingsExist(new List<String>{ 'Not_A_Real_Setting__c' });
        Test.stopTest();
    }

    // ─── getListSettings ────────────────────────────────────────────────

    @isTest
    private static void shouldReturnRelationshipLookupListSettings() {
        Relationship_Lookup__c lookup = new Relationship_Lookup__c(
            Name = 'TestRel',
            Male__c = 'Husband',
            Female__c = 'Wife',
            Neutral__c = 'Spouse'
        );
        insert lookup;

        Test.startTest();
        List<SObject> results = NppatchSettingsController.getListSettings('Relationship_Lookup__c');
        Test.stopTest();

        System.assert(results.size() > 0, 'Should return at least the inserted record');
    }

    @isTest
    private static void shouldReturnRelationshipAutoCreateListSettings() {
        Test.startTest();
        List<SObject> results = NppatchSettingsController.getListSettings('Relationship_Auto_Create__c');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should return a list');
    }

    @isTest
    private static void shouldReturnOppNamingListSettings() {
        Test.startTest();
        List<SObject> results = NppatchSettingsController.getListSettings('Opportunity_Naming_Settings__c');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should return a list');
    }

    @isTest
    private static void shouldReturnPaymentMappingListSettings() {
        Payment_Field_Mapping_Settings__c mapping = new Payment_Field_Mapping_Settings__c(
            Name = 'TestMapping',
            Opportunity_Field__c = 'Amount',
            Payment_Field__c = 'Payment_Amount__c'
        );
        insert mapping;

        Test.startTest();
        List<SObject> results = NppatchSettingsController.getListSettings('Payment_Field_Mapping_Settings__c');
        Test.stopTest();

        System.assert(results.size() > 0, 'Should return at least the inserted record');
    }

    @isTest
    private static void getListSettingsShouldThrowForDisallowedObject() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.getListSettings('Contact');
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for disallowed object');
        System.assert(errorMessage.contains('Invalid list settings object'), errorMessage);
    }

    // ─── createListSetting ──────────────────────────────────────────────

    @isTest
    private static void shouldCreateListSetting() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Name' => 'NewTestRel',
            'Male__c' => 'Brother',
            'Female__c' => 'Sister',
            'Neutral__c' => 'Sibling'
        };

        Test.startTest();
        Id recordId = NppatchSettingsController.createListSetting('Relationship_Lookup__c', fieldValues);
        Test.stopTest();

        System.assertNotEquals(null, recordId, 'Should return the new record Id');
        Relationship_Lookup__c created = [SELECT Name, Male__c FROM Relationship_Lookup__c WHERE Id = :recordId];
        System.assertEquals('NewTestRel', created.Name);
        System.assertEquals('Brother', created.Male__c);
    }

    @isTest
    private static void createListSettingShouldIgnoreIdAndAttributes() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Name' => 'IgnoreIdTest',
            'Id' => '000000000000000',
            'attributes' => 'something',
            'Male__c' => 'Uncle',
            'Female__c' => 'Aunt',
            'Neutral__c' => 'Relative'
        };

        Test.startTest();
        Id recordId = NppatchSettingsController.createListSetting('Relationship_Lookup__c', fieldValues);
        Test.stopTest();

        System.assertNotEquals(null, recordId, 'Should create successfully despite Id/attributes');
    }

    @isTest
    private static void createListSettingShouldThrowForDisallowedObject() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.createListSetting('Contact', new Map<String, Object>{ 'Name' => 'test' });
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for disallowed object');
    }

    // ─── updateListSetting ──────────────────────────────────────────────

    @isTest
    private static void shouldUpdateListSetting() {
        Relationship_Lookup__c lookup = new Relationship_Lookup__c(
            Name = 'UpdateTest',
            Male__c = 'OldMale',
            Female__c = 'OldFemale',
            Neutral__c = 'OldNeutral'
        );
        insert lookup;

        Map<String, Object> fieldValues = new Map<String, Object>{
            'Male__c' => 'NewMale'
        };

        Test.startTest();
        NppatchSettingsController.updateListSetting('Relationship_Lookup__c', lookup.Id, fieldValues);
        Test.stopTest();

        Relationship_Lookup__c updated = [SELECT Male__c FROM Relationship_Lookup__c WHERE Id = :lookup.Id];
        System.assertEquals('NewMale', updated.Male__c, 'Male value should be updated');
    }

    @isTest
    private static void updateListSettingShouldIgnoreIdAndAttributes() {
        Relationship_Lookup__c lookup = new Relationship_Lookup__c(
            Name = 'IgnoreTest',
            Male__c = 'M',
            Female__c = 'F',
            Neutral__c = 'N'
        );
        insert lookup;

        Map<String, Object> fieldValues = new Map<String, Object>{
            'Id' => '000000000000000',
            'attributes' => 'something',
            'Male__c' => 'Updated'
        };

        Test.startTest();
        NppatchSettingsController.updateListSetting('Relationship_Lookup__c', lookup.Id, fieldValues);
        Test.stopTest();

        Relationship_Lookup__c updated = [SELECT Male__c FROM Relationship_Lookup__c WHERE Id = :lookup.Id];
        System.assertEquals('Updated', updated.Male__c);
    }

    @isTest
    private static void updateListSettingShouldThrowForDisallowedObject() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.updateListSetting('Contact', null, new Map<String, Object>());
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for disallowed object');
    }

    // ─── deleteListSetting ──────────────────────────────────────────────

    @isTest
    private static void shouldDeleteListSetting() {
        Relationship_Lookup__c lookup = new Relationship_Lookup__c(
            Name = 'DeleteTest',
            Male__c = 'M',
            Female__c = 'F',
            Neutral__c = 'N'
        );
        insert lookup;

        Test.startTest();
        NppatchSettingsController.deleteListSetting('Relationship_Lookup__c', lookup.Id);
        Test.stopTest();

        List<Relationship_Lookup__c> remaining = [SELECT Id FROM Relationship_Lookup__c WHERE Id = :lookup.Id];
        System.assertEquals(0, remaining.size(), 'Record should be deleted');
    }

    @isTest
    private static void deleteListSettingShouldThrowForDisallowedObject() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.deleteListSetting('Contact', null);
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for disallowed object');
    }

    // ─── Trigger Handler CRUD ───────────────────────────────────────────

    @isTest
    private static void shouldReturnTriggerHandlers() {
        Trigger_Handler__c handler = new Trigger_Handler__c(
            Object__c = 'Account',
            Class__c = 'ACCT_Accounts_TDTM',
            Load_Order__c = 1,
            Trigger_Action__c = 'BeforeInsert;BeforeUpdate',
            Active__c = true
        );
        insert handler;

        Test.startTest();
        List<Trigger_Handler__c> results = NppatchSettingsController.getTriggerHandlers();
        Test.stopTest();

        System.assert(results.size() > 0, 'Should return at least the inserted handler');
    }

    @isTest
    private static void shouldCreateTriggerHandler() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Object__c' => 'Contact',
            'Class__c' => 'TestHandler_TDTM',
            'Load_Order__c' => 99,
            'Trigger_Action__c' => 'AfterInsert',
            'Active__c' => true
        };

        Test.startTest();
        Id recordId = NppatchSettingsController.createTriggerHandler(fieldValues);
        Test.stopTest();

        System.assertNotEquals(null, recordId, 'Should return the new handler Id');
        Trigger_Handler__c created = [
            SELECT Object__c, Class__c, User_Managed__c
            FROM Trigger_Handler__c
            WHERE Id = :recordId
        ];
        System.assertEquals('Contact', created.Object__c);
        System.assertEquals('TestHandler_TDTM', created.Class__c);
        System.assertEquals(true, created.User_Managed__c, 'User_Managed__c should be set to true');
    }

    @isTest
    private static void createTriggerHandlerShouldIgnoreIdAndAttributes() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Id' => '000000000000000',
            'attributes' => 'something',
            'Object__c' => 'Account',
            'Class__c' => 'TestHandler2_TDTM',
            'Load_Order__c' => 99,
            'Trigger_Action__c' => 'AfterInsert',
            'Active__c' => true
        };

        Test.startTest();
        Id recordId = NppatchSettingsController.createTriggerHandler(fieldValues);
        Test.stopTest();

        System.assertNotEquals(null, recordId, 'Should create successfully despite Id/attributes');
    }

    @isTest
    private static void shouldDeleteTriggerHandler() {
        Trigger_Handler__c handler = new Trigger_Handler__c(
            Object__c = 'Account',
            Class__c = 'DeleteMe_TDTM',
            Load_Order__c = 1,
            Trigger_Action__c = 'BeforeInsert',
            Active__c = true
        );
        insert handler;

        Test.startTest();
        NppatchSettingsController.deleteTriggerHandler(handler.Id);
        Test.stopTest();

        List<Trigger_Handler__c> remaining = [SELECT Id FROM Trigger_Handler__c WHERE Id = :handler.Id];
        System.assertEquals(0, remaining.size(), 'Handler should be deleted');
    }

    // ─── getFieldDescribes ──────────────────────────────────────────────

    @isTest
    private static void shouldReturnFieldDescribesForStandardObject() {
        Test.startTest();
        List<Map<String, String>> fields =
            NppatchSettingsController.getFieldDescribes('Opportunity');
        Test.stopTest();

        System.assert(fields.size() > 0, 'Should return fields for Opportunity');
        // Verify structure of returned data
        Map<String, String> firstField = fields[0];
        System.assert(firstField.containsKey('label'), 'Each field should have a label');
        System.assert(firstField.containsKey('value'), 'Each field should have a value (API name)');
        System.assert(firstField.containsKey('type'), 'Each field should have a type');
    }

    @isTest
    private static void shouldReturnFieldDescribesForCustomObject() {
        Test.startTest();
        List<Map<String, String>> fields =
            NppatchSettingsController.getFieldDescribes('OppPayment__c');
        Test.stopTest();

        System.assert(fields.size() > 0, 'Should return fields for OppPayment__c');
    }

    @isTest
    private static void getFieldDescribesShouldThrowForInvalidObject() {
        String errorMessage;

        Test.startTest();
        try {
            NppatchSettingsController.getFieldDescribes('NotARealObject__x');
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals(null, errorMessage, 'Should throw for invalid SObject');
        System.assert(errorMessage.contains('Invalid SObject type'), errorMessage);
    }

    // ─── getMultiObjectFieldDescribes ───────────────────────────────────

    @isTest
    private static void shouldReturnMultiObjectFieldDescribes() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result =
            NppatchSettingsController.getMultiObjectFieldDescribes(
                new List<String>{ 'Opportunity', 'Account' }
            );
        Test.stopTest();

        System.assert(result.containsKey('Opportunity'), 'Should have Opportunity key');
        System.assert(result.containsKey('Account'), 'Should have Account key');
        System.assert(result.get('Opportunity').size() > 0, 'Opportunity should have fields');
        System.assert(result.get('Account').size() > 0, 'Account should have fields');
    }

    @isTest
    private static void multiObjectShouldReturnEmptyListForInvalidObject() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result =
            NppatchSettingsController.getMultiObjectFieldDescribes(
                new List<String>{ 'Opportunity', 'NotARealObject__x' }
            );
        Test.stopTest();

        System.assert(result.get('Opportunity').size() > 0, 'Valid object should have fields');
        System.assertEquals(0, result.get('NotARealObject__x').size(),
            'Invalid object should return empty list');
    }

    // ─── getAddressValidators ───────────────────────────────────────────

    @isTest
    private static void shouldReturnAddressValidators() {
        Test.startTest();
        List<Map<String, String>> validators =
            NppatchSettingsController.getAddressValidators();
        Test.stopTest();

        // May or may not find validators depending on what's deployed,
        // but should not throw
        System.assertNotEquals(null, validators, 'Should return a list');
        if (validators.size() > 0) {
            System.assert(validators[0].containsKey('className'), 'Each validator should have className');
            System.assert(validators[0].containsKey('serviceName'), 'Each validator should have serviceName');
            System.assert(validators[0].containsKey('defaultUrl'), 'Each validator should have defaultUrl');
        }
    }
}
