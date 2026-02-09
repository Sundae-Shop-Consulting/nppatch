/*
    Copyright (c) 2011, Salesforce.org
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
* @date 2011 (2.3)
* @group Address Management
* @description test class for the Copy Address button controller
*/
@isTest(isParallel=true)
private with sharing class ADDR_CopyAddrHHObjBTN_TEST {
    private static Contact contactRecord;
    private static Household__c householdRecord;
    private static ADDR_CopyAddrHHObjBTN_CTRL copyAddressCtrl;
    private static UTIL_Permissions_TEST.Stub mockPerms = new UTIL_Permissions_TEST.Stub();

    /***
    * @description Create records common to test methods
    */
    @TestSetup
    private static void createRecordData() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new Contacts_and_Orgs_Settings__c(Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR)
        );

        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new Households_Settings__c(Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR)
        );

        Household__c householdRecord = new Household__c(
            MailingStreet__c = '123 Main St.',
            MailingState__c = 'Pennsylvania',
            MailingPostalCode__c = '18940',
            MailingCity__c = 'Newtown',
            MailingCountry__c = 'United States'
        );
        insert householdRecord;

        Contact contactRecord = new Contact(
            Household__c = householdRecord.Id,
            LastName = 'Copy Address Last Name',
            MailingStreet = '1 Oak Lane',
            MailingState = 'British Columbia',
            MailingPostalCode = '98122',
            MailingCity = 'Vancouver',
            MailingCountry = 'Canada'
        );
        insert contactRecord;
    }

    /***
    * @description Verify the the Contact address is copied to the Household
    */
    @isTest
    private static void shouldCopyAddressFromContact() {
        getRecordData();
        createCopyAddressBtnCtrl(contactRecord.Id);

        System.assertNotEquals(contactRecord.MailingStreet, householdRecord.MailingStreet__c, 'The original addresses should not match.');

        copyAddressCtrl.copy();

        householdRecord = getHouseholdRecordData();
        System.assertEquals(contactRecord.MailingStreet, householdRecord.MailingStreet__c, 'The household address should be updated to match the contact.');
        verifyNoteRecordCount(householdRecord.Id);
    }

    /***
    * @description Verify the the Household address is copied to the Contact
    */
    @isTest
    private static void shouldCopyAddressFromHousehold() {
        getRecordData();
        createCopyAddressBtnCtrl(householdRecord.Id);
        System.assertNotEquals(householdRecord.MailingStreet__c, contactRecord.MailingStreet, 'The original addresses should not match.');

        copyAddressCtrl.copy();

        contactRecord = getContactRecordData();
        System.assertEquals(householdRecord.MailingStreet__c, contactRecord.MailingStreet, 'The contact address should be updated to match the contact.');
        verifyNoteRecordCount(contactRecord.Id);
    }

    /***
    * @description Verify an error will display when an Account Id is provided
    */
    @isTest
    private static void shouldErrorWhenCopyAddressFromAccount() {
        Account accountRecord = new Account(Name = 'Copy Address Error Org');
        insert accountRecord;
        createCopyAddressBtnCtrl(accountRecord.Id);

        copyAddressCtrl.copy();

        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.AddressCopyUnknownObject);
    }

    /***
    * @description Verifies a confirmation message is displayed when button clicked
    */
    @isTest
    private static void shouldDisplayConfirmationMessageWhenBtnClicked() {
        getRecordData();
        createCopyAddressBtnCtrl(contactRecord.Id);

        UTIL_UnitTestData_TEST.assertPageHasMessage(System.Label.addrCopyConAddBtnConfirm, ApexPages.Severity.INFO);
    }

    /***
    * @description Verifies an error message is displayed when a user does not have contact read permissions
    */
    @isTest
    private static void shouldErrorWhenBtnClickedWithoutContactReadPerms() {
        getRecordData();
        mockPerms.hasRead = false;
        createCopyAddressBtnCtrl(contactRecord.Id);

        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.addrCopyConAddBtnFls);
        System.assertEquals(Contact.SObjectType, mockPerms.readSObjType);
        System.assert(mockPerms.readSObjFields.contains(Contact.MailingStreet));
    }

    /***
    * @description Verifies an error message is displayed when a user does not have household read permissions
    */
    @isTest
    private static void shouldErrorWhenBtnClickedWithoutHHReadPerms() {
        getRecordData();
        mockPerms.hasRead = false;
        createCopyAddressBtnCtrl(householdRecord.Id);

        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.addrCopyConAddBtnFls);
        System.assertEquals(Household__c.SObjectType, mockPerms.readSObjType);
        System.assert(mockPerms.readSObjFields.contains(Household__c.MailingStreet__c));
    }

    /***
    * @description Verifies an error message is displayed when a user does not have contact update permissions
    */
    @isTest
    private static void shouldErrorWhenBtnClickedWithoutContactUpdatePerms() {
        getRecordData();
        mockPerms.hasUpdate = false;
        createCopyAddressBtnCtrl(householdRecord.Id);

        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.addrCopyConAddBtnFls);
        System.assertEquals(Contact.SObjectType, mockPerms.updateSObjType);
        System.assert(mockPerms.updateSObjFields.contains(Contact.MailingStreet));
    }

    /***
    * @description Verifies an error message is displayed when a user does not have household update permissions
    */
    @isTest
    private static void shouldErrorWhenBtnClickedWithoutHHUpdatePerms() {
        getRecordData();
        mockPerms.hasUpdate = false;
        createCopyAddressBtnCtrl(contactRecord.Id);

        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.addrCopyConAddBtnFls);
        System.assertEquals(Household__c.SObjectType, mockPerms.updateSObjType);
        System.assert(mockPerms.updateSObjFields.contains(Household__c.MailingStreet__c));
    }

    /***
    * @description Verifies an error message is displayed
    * when a user does not have create permission on Address SObject
    */
    @isTest
    private static void shouldErrorWhenBtnClickedWithoutAddressCreatePerm() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        
        getRecordData();
        mockPerms.hasCreate = false;
        createCopyAddressBtnCtrl(householdRecord.Id);

        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.addrCopyConAddBtnFls);

        Address__c defaultAddress = getDefaultAddressRecord();
        System.assertNotEquals(null, defaultAddress, 'Default address should exist for the Contact');
        System.assertEquals(defaultAddress.MailingStreet__c, contactRecord.MailingStreet,
            'Address on Contact should be unchanged and not copied from the household');

        System.assertEquals(Address__c.SObjectType, mockPerms.createSObjType,
            'The create permission on Address__c SObject should be checked');
        System.assert(mockPerms.createSObjFields.contains(Address__c.MailingStreet__c),
            'The create permission on Address__c SObject fields should be checked');
    }

    /***
    * @description Verifies address on Contact is updated from Household
    * when user does not have create permission on Address SObject
    * and the custom settings for address management is disabled
    * meaning the Address record is not created after the address being copied.
    */
    @isTest
    private static void shouldCopyAddressFromHouseholdWhenSettingsDisabledAndNoCreateAddressPerms() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c(
            Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
            Household_Account_Addresses_Disabled__c = true
        ));

        getRecordData();
        mockPerms.hasCreate = false;
        createCopyAddressBtnCtrl(householdRecord.Id);

        System.assertEquals(false, ApexPages.hasMessages(ApexPages.Severity.ERROR),
            'No error message should be displayed on the page: ' + ApexPages.getMessages()
        );
    }

    /***
    * @description Verifies address on Contact is updated from Household
    * when user has create permission on Address SObject
    * and specified Address fields editable
    */
    @isTest
    private static void shouldCopyAddressFromHouseholdWhenUserHasCreateAddressPerms() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        getRecordData();
        createCopyAddressBtnCtrl(householdRecord.Id);

        System.assertNotEquals(householdRecord.MailingStreet__c, contactRecord.MailingStreet,
            'The Address on Contact and Household should be different');

        Test.startTest();
        copyAddressCtrl.copy();
        Test.stopTest();

        //refresh the Contact Record and get the default address
        contactRecord = getContactRecordData();
        Address__c defaultAddress = getDefaultAddressRecord();

        System.assertNotEquals(null, defaultAddress, 'Default address should exist for the Contact');
        System.assertEquals(householdRecord.MailingStreet__c, contactRecord.MailingStreet,
            'The Address on Contact should be copied from the Household');
        System.assertEquals(defaultAddress.MailingStreet__c, contactRecord.MailingStreet,
            'Default Address should match the new Contact Address');

        System.assertEquals(Address__c.SObjectType, mockPerms.createSObjType,
            'The create permission on Address__c SObject should be checked');
    }

    /***
    * @description The page reference returned contains the record Id passed to the controller
    */
    @isTest
    private static void shouldReturnPageReferenceWithRecordId() {
        getRecordData();
        createCopyAddressBtnCtrl(contactRecord.Id);

        System.assert(String.valueOf(copyAddressCtrl.close()).contains(contactRecord.Id), 'The page ref should contain the record Id.' );
    }

    /***
    * @description The page reference returned should be the user home page when the id is not supported
    */
    @isTest
    private static void shouldReturnHomePageWhenUnsupportedRecordId() {
        Account accountRecord = new Account(Name = 'Copy Address Unsupported Org');
        insert accountRecord;
        createCopyAddressBtnCtrl(accountRecord.Id);

        System.assert(String.valueOf(copyAddressCtrl.close()).contains('home'), 'The page ref should be the user home page.' );
    }

    // Helpers
    ////////////////

    /***
    * @description Populates the record variables with the records generated in test setup
    * @return void
    */
    private static void getRecordData() {
        householdRecord = getHouseholdRecordData();
        contactRecord = getContactRecordData();
    }

    /***
    * @description Queries the household record created in test setup
    * @return Household__c
    */
    private static Household__c getHouseholdRecordData() {
        return [
            SELECT Id, MailingStreet__c, MailingState__c,
                MailingPostalCode__c, MailingCity__c, MailingCountry__c
            FROM Household__c
            LIMIT 1
        ];
    }

    /***
    * @description Queries the contact record created in test setup
    * @return Contact
    */
    private static Contact getContactRecordData() {
        return [
            SELECT Id, AccountId, MailingStreet, MailingState, MailingPostalCode, MailingCity, MailingCountry
            FROM Contact
            LIMIT 1
        ];
    }

    /***
    * @description Returns the default address record
    * @return Address__c
    */
    private static Address__c getDefaultAddressRecord() {
        List<Address__c> addresses = [
            SELECT Household_Account__c,
                MailingStreet__c, MailingState__c,
                MailingPostalCode__c, MailingCity__c,
                MailingCountry__c
            FROM Address__c
            WHERE Default_Address__c = true
        ];

        System.assertEquals(1, addresses.size(), 'One default address should exist: ' + addresses);

        return addresses[0];
    }

    /***
    * @description Sets the current page to page controller from the button click of provided record Id
    * with user having permissions by default.
    * @param recordId - the record Id to pass to the controller
    */
    private static void createCopyAddressBtnCtrl(Id recordId) {
        Test.setCurrentPageReference(new PageReference('Page.' + UTIL_Namespace.StrTokenNSPrefix('ADDR_CopyAddrHHObjBTN')));
        System.currentPageReference().getParameters().put('id', recordId);
        copyAddressCtrl = new ADDR_CopyAddrHHObjBTN_CTRL();
        copyAddressCtrl.perms = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class, mockPerms);

        copyAddressCtrl.buttonClick();
    }

    /***
    * @description Verify a note was created for the provided record Id
    * @param parentId - the id of the record the note belongs to
    * @return void
    */
    private static void verifyNoteRecordCount(Id parentId) {
        System.assertEquals(1, [SELECT count() FROM Note where ParentID = :parentId]);
    }

}