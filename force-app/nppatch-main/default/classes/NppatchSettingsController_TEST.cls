@isTest
private with sharing class NppatchSettingsController_TEST {

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

    @isTest
    private static void shouldSaveHouseholdsSettings() {
        // Ensure org defaults exist
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
    private static void shouldReturnRecordTypeOptions() {
        Test.startTest();
        List<Map<String, String>> options =
            NppatchSettingsController.getRecordTypeOptions('Opportunity');
        Test.stopTest();

        // In a test context, record types may or may not exist.
        // We just verify the method does not throw.
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

    @isTest
    private static void shouldReturnAdminStatus() {
        Test.startTest();
        Boolean result = NppatchSettingsController.isAdmin();
        Test.stopTest();

        // Running user in test context is typically an admin
        System.assertNotEquals(null, result, 'Should return a boolean value');
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
}
