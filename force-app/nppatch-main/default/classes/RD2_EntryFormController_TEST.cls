/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Enhanced Recurring Donations Entry Form LWC Controller Tests
*
*/
@IsTest
private with sharing class RD2_EntryFormController_TEST {

    private static final Date START_DATE = Date.newInstance(2019, 3, 1);
    private static final String COMMITMENT_ID = 'TEST-COMMITMENT-ID';
    private static final String PAYMENT_METHOD_TOKEN = 'token-abcd-efgh-ijkl-mnop-qrst';
    private static final String CARD_LAST_4 = '1234';
    private static final String CARD_EXPIRATION_MONTH = '11';
    private static final String CARD_EXPIRATION_YEAR = '2019';
    private static final String EVENT_VERSION = '1';
    private static final String NO_CREATE_PERMISSION = 'NoCreate';

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();

    private static OrgConfig orgConfig = new OrgConfig();

    /**
    * @description Returns true if tests should be skipped in 2GP namespaced context
    */
    private static Boolean shouldSkipIn2GP() {
        return String.isNotBlank(UTIL_Namespace.getNamespace());
    }

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        // Assign admin permission set to ensure CRUD/FLS access
        UTIL_TestPermissions.assignAdminPermissionSet();


        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(c.Id)
            .withAmount(25)
            .withDefaultValues()
            .withInstallmentPeriodWeekly()
            .withDayOfMonth('1')
            .withInstallmentFrequency(2)
            .build();
        insert rd;
    }

    /***
    * @description Verifies that Entry Form Controller gathers the correct org setting
    */
    @IsTest
    private static void shouldReturnSettings() {
        if (shouldSkipIn2GP()) return;
        Id accountId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);

        Test.startTest();
        RD2_AppView initialView = RD2_EntryFormController.getInitialView(accountId, null);
        Test.stopTest();

        System.assertEquals(RD2_NamingService.isAutomaticNamingEnabled, initialView.isAutoNamingEnabled,
            'Recurring Donation Auto Naming setting should be returned accordingly');
        System.assertEquals(UserInfo.isMultiCurrencyOrganization(), initialView.isMultiCurrencyEnabled,
            'Multi Currency Org should be detected in the configuration.');
        System.assertEquals(String.valueOf(Account.SObjectType), initialView.parentSObjectType,
            'Parent Sobject type should be correctly identified when value is not null');

        System.assertEquals(true, initialView.InstallmentPeriodPermissions.get('Createable'),
            'Installment_Period__c.IsCreatable should return true');
    }

    /***
    * @description Verifies whether the org is the Elevate customer
    * in order to display the Elevate credit card widget if so.
    */
    @IsTest
    private static void newRecordShouldDefaultStartDate() {
        Test.startTest();
        RD2_AppView initialView = RD2_EntryFormController.getInitialView(null, null);
        Test.stopTest();

        System.assertEquals(initialView.record.dateEstablished, Date.today(), 'Date established should default to today.');
    }

    /***
    * @description Verifies whether the org is the Elevate customer
    * in order to display the Elevate credit card widget if so.
    */
    @IsTest
    private static void newRecordShouldDefaultDateEstablished() {
        Test.startTest();
        RD2_AppView initialView = RD2_EntryFormController.getInitialView(null, null);
        Test.stopTest();

        System.assertEquals(initialView.record.startDate, Date.today(), 'Start date should default to today.');
    }

    /***
    * @description Verifies that Entry Form Controller returns the expected results for Account for Donor Type
    */
    @IsTest
    private static void shouldReturnAccountDonorType() {
        if (shouldSkipIn2GP()) return;

        Account a = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert a;

        Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withAccount(a.Id)
            .withAmount(25)
            .withDefaultValues()
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1')
            .build();
        insert rd;

        Test.startTest();
        RD2_AppView view = RD2_EntryFormController.getInitialView(a.Id, rd.Id);
        String donorType = view.record.donorType;
        String period = view.record.recurringPeriod;
        Test.stopTest();

        System.assertEquals('Account', donorType);
        System.assertEquals('Monthly', period);
    }

    /***
    * @description Verifies that Entry Form Controller returns the expected results for Contact for Donor Type
    */
    @IsTest
    private static void shouldReturnContactDonorType() {
        if (shouldSkipIn2GP()) return;
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        

        Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        RD2_AppView view = RD2_EntryFormController.getInitialView(null, rd.Id);
        String donorType = view.record.donorType;
        String period = view.record.recurringPeriod;
        Integer frequency = view.record.recurringFrequency;
        Test.stopTest();

        System.assertEquals('Contact', donorType);
        System.assertEquals('Weekly', period);
        System.assertEquals(2, frequency);
    }

    /**
     * @description Validate that the System Admin User reports that they have the required field permissions
     */
    @IsTest
    private static void shouldReturnTrueWhenUserHasPermissions() {
        if (shouldSkipIn2GP()) return;
        Boolean hasPerms = RD2_EntryFormController.hasRequiredFieldPermissions();
        System.assertEquals(true, hasPerms, 'The Admin User should have permissions');
    }

    /**
     * @description Validate that a Standard User w/o Read permission on a single RD  field reports that they
     * are missing the required field permissions
     */
    @IsTest
    private static void shouldReturnFalseWhenUserIsMissingPermissions() {
        if (shouldSkipIn2GP()) return;
        User stdUser = UTIL_UnitTestData_TEST.createStandardProfileUser();

        Id stdProfileId = [SELECT Id FROM Profile WHERE Name = :UTIL_Profile.PROFILE_STANDARD_USER LIMIT 1].Id;

        FieldPermissions fldPerm = [
            SELECT Id, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE Parent.ProfileId = :stdProfileId
            AND Field = 'Recurring_Donation__c.Installment_Period__c'
        ];
        fldPerm.PermissionsRead = false;
        fldPerm.PermissionsEdit = false;
        update fldPerm;

        Test.startTest();
        System.runAs(stdUser) {
            Boolean hasPerms = RD2_EntryFormController.hasRequiredFieldPermissions();
            System.assertEquals(false, hasPerms, 'The Standard User should be missing permissions');
        }
        Test.stopTest();
    }

    /***
    * @description Verifies that Entry Form Controller excluded all NPSP packaged field and predefined excluded fields
    */
    @IsTest
    private static void shouldReturnRD2CustomFieldsWithoutNPSPNameSpaceAndExcludedFields() {
        Test.startTest();
        List<InputFieldView> customFields = RD2_EntryFormController.getCustomFieldSectionFields();
        Test.stopTest();

        Set<String> excludedCustomFields = RD2_Settings.getExcludedCustomFields();

        for (InputFieldView field : customFields) {
            System.assert(!excludedCustomFields.contains(field.apiName),
                'Excluded fields should not be return:' + field.apiName);
            System.assert(!field.apiName.startsWith('%%%NAMESPACE%%%'),
                'NPPatch package field should not be return:' + field.apiName);
            System.assert(!field.apiName.startsWith(''),
                'NPPatch package field should not be return:' + field.apiName);
        }
    }

    @IsTest
    private static void canSaveRecurringDonation() {
        if (shouldSkipIn2GP()) return;
        Contact donorContact = getContact();

        RD2_SaveRequest req = new RD2_SaveRequest();

        req.dayOfMonth = '15';
        req.startDate = Date.newInstance(2022, 1, 15);
        req.dateEstablished = Date.newInstance(2022, 1, 15);
        req.recurringFrequency = 1;
        req.contactId = donorContact.Id;
        req.recurringStatus = 'Active';
        req.donationValue = 5;
        req.recurringType = 'Open';
        req.recurringPeriod = 'Monthly';
        req.paymentMethod = 'Credit Card';

        SaveResultView result = RD2_EntryFormController.saveRecurringDonation(req);

        System.assert(result.success, 'RD not inserted successfully');
        System.assertNotEquals(result.recordId, null, 'Save result should have an Id');
    }

    @IsTest
    private static void canSaveRDWithCustomFieldsNotCreateable() {
        Contact donorContact = getContact();

        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock().canUpdate();
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class,
                utilPermissionsMockInstance);
        UTIL_Permissions.setInstance(utilPermissionsMock);

        RD2_SaveRequest req = new RD2_SaveRequest();
        req.dayOfMonth = '15';
        req.startDate = Date.newInstance(2022, 1, 15);
        req.dateEstablished = Date.newInstance(2022, 1, 15);
        req.recurringFrequency = 1;
        req.contactId = donorContact.Id;
        req.recurringStatus = 'Active';
        req.donationValue = 5;
        req.recurringType = 'Open';
        req.recurringPeriod = 'Monthly';
        req.paymentMethod = 'Credit Card';
        req.customFieldValues = new Map<String, Object> {
            NO_CREATE_PERMISSION => 'TestNoCreateValue1',
            NO_CREATE_PERMISSION + '_1' => 'TestNoCreateValue2'
        };

        SaveResultView result = RD2_EntryFormController.saveRecurringDonation(req);

        for (String fieldName : req.customFieldValues.keySet()) {
            System.assertNotEquals(NO_CREATE_PERMISSION, fieldName.substringBefore('_'), 'All fields that are not' +
                ' createable should be removed from the save request.');
        }

        System.assert(result.success, 'RD not inserted successfully');
        System.assertNotEquals(result.recordId, null, 'Save result should have an Id');
    }

    @IsTest
    private static void rdCustomFieldsMapToCorrectFieldType() {

        RD2_SaveRequest saveRequest = new RD2_SaveRequest();
        saveRequest.customFieldValues = new Map<String, Object> {
            'TestField' => 'TestFieldValue'
        };

        RD2_SaveRequestHelperMock saveRequestHelperMockInstance = new RD2_SaveRequestHelperMock();
        RD2_SaveRequestHelper saveRequestHelperMock = (RD2_SaveRequestHelper)
            Test.createStub(RD2_SaveRequestHelper.class, saveRequestHelperMockInstance);
        saveRequest.requestHelper = saveRequestHelperMock;

        UTIL_DescribeMock describeMock = getDescribeMock();

        testMapToBoolean(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDate(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDateTime(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToTime(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToCurrency(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDouble(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToInteger(describeMock, saveRequest, saveRequestHelperMockInstance);
    }

    @IsTest
    private static void rdCustomFieldsMapToCorrectFieldTypeWithNullValue() {

        RD2_SaveRequest saveRequest = new RD2_SaveRequest();
        saveRequest.customFieldValues = new Map<String, Object> {
            'TestField' => null
        };

        RD2_SaveRequestHelperMock saveRequestHelperMockInstance = new RD2_SaveRequestHelperMock();
        RD2_SaveRequestHelper saveRequestHelperMock = (RD2_SaveRequestHelper)
                Test.createStub(RD2_SaveRequestHelper.class, saveRequestHelperMockInstance);
        saveRequest.requestHelper = saveRequestHelperMock;

        UTIL_DescribeMock describeMock = getDescribeMock();

        testMapToBoolean(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDate(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDateTime(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToTime(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToCurrency(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToDouble(describeMock, saveRequest, saveRequestHelperMockInstance);
        testMapToInteger(describeMock, saveRequest, saveRequestHelperMockInstance);
    }

    @IsTest
    private static void saveRequestMapsFieldsToRecurringDonation() {
        RD2_SaveRequest req = new RD2_SaveRequest();

        Id fakeCampaignId = UTIL_UnitTestData_TEST.mockId(Campaign.SObjectType);
        Id fakeContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        Id fakeRdId = UTIL_UnitTestData_TEST.mockId(Recurring_Donation__c.SObjectType);

        Date fakeDate =  Date.newInstance(2022, 1, 15);
        Date fakeDate2 =  Date.newInstance(2022, 1, 14);
        req.dayOfMonth = '15';
        req.recurringStatus = 'Active';
        req.startDate = fakeDate;
        req.dateEstablished = fakeDate2;
        req.recurringFrequency = 1;
        req.contactId = fakeContactId;
        req.recurringStatus = 'Active';
        req.donationValue = 5;
        req.recurringType = 'Open';
        req.recurringPeriod = 'Monthly';
        req.paymentMethod = 'Credit Card';
        req.campaignId = fakeCampaignId;
        req.customFieldValues = new Map<String, Object>();
        req.cardExpirationYear = '2025';
        req.cardExpirationMonth = '2';
        req.recordId = fakeRdId;

        Recurring_Donation__c rd = req.toRecord();

        System.assertEquals('15', rd.Day_of_Month__c);
        System.assertEquals(fakeDate, rd.StartDate__c);
        System.assertEquals(fakeDate2, rd.Date_Established__c);
        System.assertEquals(1, rd.InstallmentFrequency__c);
        System.assertEquals(fakeCampaignId, rd.Recurring_Donation_Campaign__c);
        System.assertEquals('Credit Card', rd.PaymentMethod__c);
        System.assertEquals(5, rd.Amount__c);
        System.assertEquals('2025', rd.CardExpirationYear__c);
        System.assertEquals('2', rd.CardExpirationMonth__c);
        System.assertEquals('Active', rd.Status__c);
        System.assertEquals(fakeRdId, rd.Id);
    }


    @IsTest
    private static void saveResponseIncludesErrorInformation() {
        if (shouldSkipIn2GP()) return;
        Contact donorContact = getContact();

        RD2_SaveRequest req = new RD2_SaveRequest();

        req.dayOfMonth = '15';
        req.startDate = Date.newInstance(2022, 1, 15);
        req.dateEstablished = Date.newInstance(2022, 1, 15);
        req.recurringFrequency = 1;
        req.contactId = donorContact.Id;
        req.recurringStatus = 'Active';
        req.donationValue = -1;
        req.recurringType = 'Open';
        req.recurringPeriod = 'Monthly';
        req.paymentMethod = 'Credit Card';

        SaveResultView result = RD2_EntryFormController.saveRecurringDonation(req);

        System.assertEquals(false, result.success, 'Expected RD2SaveResult success to be false');
        System.assertEquals(null, result.recordId, 'Expected empty record Id');
        System.assertEquals(Label.RD2_AmountMustBeValid, result.errors[0].message, 'Wrong error message');
    }

    // Helpers
    ////////////////

    /****
    * @description Simulates a successful commitment creation callout
    * @return String
    */
    private static void mockRecordCreatedCalloutResponse() {
        UTIL_Http_TEST.mockRecordCreatedCalloutResponse(mockSuccessResponseBody());
    }

    /****
    * @description Returns a mock response body that mimics response body returned from Elevate
    * when a commitment is created
    * @return String
    */
    private static String mockSuccessResponseBody() {
        return '{"id":"' + COMMITMENT_ID
            + '","status":"ACTIVE","statusReason":"COMMITMENT_CREATED"'
            + ',"version":"' + EVENT_VERSION +'"'
            + ',"cardData":{"last4":"' + CARD_LAST_4
            + '","expirationMonth":"' + CARD_EXPIRATION_MONTH
            + '","expirationYear":"' + CARD_EXPIRATION_YEAR
            + '"}}';
    }

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId, Account.Name
            FROM Contact
            LIMIT 1
        ];
    }

    /****
    * @description Returns a new Recurring Donation record
    * @return Recurring_Donation__c
    */
    private static Recurring_Donation__c buildRecurringDonation() {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(getContact().Id)
            .withAmount(100)
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withDayOfMonth('1')
            .withPaymentMethod(RD2_Constants.PAYMENT_PICKLIST_VALUE_CARD)
            .build();
    }

    private static void testMapToBoolean(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        describeMock.setFieldType(DisplayType.BOOLEAN);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Boolean ||
                saveRequestHelperMockInstance.paramValues()[2] == null, 'The boolean value should correctly map to ' +
                'the boolean field type.');
    }

    private static void testMapToDate(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
                'TestDate' => String.valueOf(Date.today())
        };

        describeMock.setFieldType(DisplayType.DATE);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled);
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Date ||
                saveRequestHelperMockInstance.paramValues()[2] == null);
    }

    private static void testMapToDateTime(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
            'TestDatetime' => String.valueOf(Datetime.newInstance(
                Date.today().year(),
                Date.today().month(),
                Date.today().day()
            ))
        };

        describeMock.setFieldType(DisplayType.DATETIME);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Datetime ||
            saveRequestHelperMockInstance.paramValues()[2] == null, 'The datetime value should correctly map to ' +
                'the datetime field type.');
    }

    private static void testMapToTime(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
            'TestTime' => String.valueOf(Time.newInstance(
                18, 30, 2, 20
            ))
        };

        describeMock.setFieldType(DisplayType.TIME);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Time ||
            saveRequestHelperMockInstance.paramValues()[2] == null, 'The time value should correctly map to ' +
                'the time field type.');
    }

    private static void testMapToCurrency(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
            'TestCurrency' => 5.00
        };

        describeMock.setFieldType(DisplayType.CURRENCY);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Double ||
            saveRequestHelperMockInstance.paramValues()[2] == null, 'The currency value should correctly map to ' +
                'the double field type.');
    }

    private static void testMapToDouble(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
            'TestDouble' => String.valueOf(15.1524)
        };

        describeMock.setFieldType(DisplayType.DOUBLE);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Double ||
            saveRequestHelperMockInstance.paramValues()[2] == null, 'The double value should correctly map to ' +
                'the double field type.');
    }

    private static void testMapToInteger(UTIL_DescribeMock describeMock,
            RD2_SaveRequest saveRequest,
            RD2_SaveRequestHelperMock saveRequestHelperMockInstance) {

        saveRequest.customFieldValues = new Map<String, Object> {
            'TestInteger' => 15
        };

        describeMock.setFieldType(DisplayType.INTEGER);
        saveRequest.toRecord();
        System.assert(saveRequestHelperMockInstance.setRecurringDonationFieldCalled, 'The setRecurringDonationField ' +
                'method should be called.');
        System.assert(saveRequestHelperMockInstance.paramValues()[2] instanceof Integer ||
            saveRequestHelperMockInstance.paramValues()[2] == null, 'The integer value should correctly map to ' +
                'the integer field type.');
    }

    private static UTIL_DescribeMock getDescribeMock() {
        UTIL_DescribeMock utilDescribeMockInstance = new UTIL_DescribeMock();
        UTIL_Describe utilDescribeMock = (UTIL_Describe) Test.createStub(UTIL_Describe.class,
                utilDescribeMockInstance);
        UTIL_Describe.setInstance(utilDescribeMock);

        return utilDescribeMockInstance;
    }

    public class RD2_QueryServiceMock implements StubProvider {

        Recurring_Donation__c rd;

        public RD2_QueryServiceMock(Recurring_Donation__c rd) {
            this.rd = rd;
        }

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs
        ) {
            return this.rd;
        }
    }

    private class UTIL_PermissionsMock implements StubProvider {
        Boolean canUpdate = false;

        public UTIL_PermissionsMock canUpdate() {
            canUpdate = true;

            return this;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> paramTypes, List<String> listOfParamNames,
                List<Object> args) {

            switch on stubbedMethodName {
                when 'canCreateInstanced' {
                    if (String.valueOf(args[1]).substringBefore('_').equals(NO_CREATE_PERMISSION)) {
                        return false;
                    }
                }
                when 'canUpdate' {
                    return canUpdate;
                }
            }
            return null;
        }
    }

    private class UTIL_DescribeMock implements StubProvider {
        private DisplayType fieldType;

        public UTIL_DescribeMock setFieldType(DisplayType fieldTypeArg) {
            fieldType = fieldTypeArg;

            return this;
        }

        public DisplayType fieldType() {
            return fieldType;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> paramTypes, List<String> listOfParamNames,
                List<Object> args) {

            switch on stubbedMethodName {
                when 'getFieldTypeInstance' {
                    return fieldType.name().toUpperCase();
                }
                when 'getObjectDescribeInstance' {
                    return UTIL_Describe.getObjectDescribe(Recurring_Donation__c.SObjectType);
                }
            }
            return null;
        }
    }

    private class RD2_SaveRequestHelperMock implements StubProvider {
        private Boolean setRecurringDonationFieldCalled;
        private List<Object> parameterValues;

        public List<Object> paramValues() {
            return parameterValues;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> argTypes, List<String> listOfParamNames,
                List<Object> args) {

            switch on stubbedMethodName {
                when 'setRecurringDonationField' {
                    parameterValues = args;
                    setRecurringDonationFieldCalled = true;
                }
            }
            return null;
        }
    }
}